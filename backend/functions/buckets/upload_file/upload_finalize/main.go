package function

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"cloud.google.com/go/logging"
	"cloud.google.com/go/storage"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/google/uuid"
	"google.golang.org/api/iterator"
)

var (
	storageClient *storage.Client
	bucketName    string
	logger        *log.Logger
	warningLogger *log.Logger
	errorLogger   *log.Logger
)

func init() {
	ctx := context.Background()
	var err error

	storageClient, err = storage.NewClient(ctx)
	if err != nil {
		log.Fatalf("Failed to create storage client: %v", err)
	}

	bucketName = os.Getenv("BUCKET_NAME")
	if bucketName == "" {
		bucketName = "file-chunks-"
	}

	client, err := logging.NewClient(ctx, os.Getenv("GCP_PROJECT_ID"))
	if err != nil {
		log.Fatalf("Failed to create logging client: %v", err)
	}

	logName := "upload-finalize"
	logger = client.Logger(logName).StandardLogger(logging.Info)
	warningLogger = client.Logger(logName).StandardLogger(logging.Warning)
	errorLogger = client.Logger(logName).StandardLogger(logging.Error)

	functions.HTTP("UploadFinalize", uploadFinalize)
}

func uploadFinalize(w http.ResponseWriter, r *http.Request) {
	writeHeaders(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	ctx := r.Context()

	sessionID, err := getSessionID(r)
	if err != nil {
		warningLogger.Printf("Invalid session ID: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	fileID, fileName, err := getRequiredHeaders(r)
	if err != nil {
		warningLogger.Printf("Missing headers: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	logger.Printf("Finalizing upload for session %s, fileID: %s, fileName: %s", sessionID, fileID, fileName)

	sourceBucket := storageClient.Bucket(fmt.Sprintf("%s%s", bucketName, sessionID))
	if _, err := sourceBucket.Attrs(ctx); err != nil {
		errorLogger.Printf("Failed to get source bucket: %v", err)
		http.Error(w, "Failed to get source bucket: "+err.Error(), http.StatusInternalServerError)
		return
	}

	blobs := getAllBlobs(ctx, sourceBucket, fileID)
	if len(blobs) == 0 {
		warningLogger.Printf("No file chunks found for fileID: %s", fileID)
		http.Error(w, "No file found", http.StatusNotFound)
		return
	}

	destinationBucket := storageClient.Bucket(sessionID)
	if _, err := destinationBucket.Attrs(ctx); err != nil {
		errorLogger.Printf("Failed to get destination bucket: %v", err)
		http.Error(w, "Failed to get destination bucket: "+err.Error(), http.StatusInternalServerError)
		return
	}

	fileName = fmt.Sprintf("%s-%s.%s", strings.TrimSuffix(fileName, filepath.Ext(fileName)), uuid.NewString(), filepath.Ext(fileName))

	if checkIfBlobExists(ctx, destinationBucket, fileName) {
		warningLogger.Printf("File %s already exists in destination bucket", fileName)
		http.Error(w, "File already exists", http.StatusConflict)
		return
	}

	finalObject, err := composeLargeFiles(ctx, sourceBucket, blobs, fileName)
	if err != nil {
		errorLogger.Printf("Error during large file composition: %v", err)
		http.Error(w, "Error during large file composition: "+err.Error(), http.StatusInternalServerError)
		return
	}

	finalObjectAttrs, err := finalObject.Attrs(ctx)
	if err != nil {
		errorLogger.Printf("Failed to get attributes of composed object: %v", err)
		http.Error(w, "Failed to get attributes of composed object: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if err := moveObject(ctx, sourceBucket, destinationBucket, finalObjectAttrs.Name, fileName); err != nil {
		errorLogger.Printf("Error moving final composed object: %v", err)
		http.Error(w, "Error moving final composed object: "+err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]string{"message": "File composed successfully into " + finalObjectAttrs.Name}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func writeHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-File-Id, X-File-Name")
}

func getSessionID(r *http.Request) (string, error) {
	sessionID := r.URL.Query().Get("session_id")
	if sessionID == "" {
		var data map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
			return "", fmt.Errorf("session_id is required either as a query parameter or in the JSON body")
		}
		if val, ok := data["session_id"].(string); ok {
			sessionID = val
		}
	}

	if sessionID == "" {
		return "", fmt.Errorf("session_id is required either as a query parameter or in the JSON body")
	}
	return sessionID, nil
}

func getRequiredHeaders(r *http.Request) (string, string, error) {
	fileID := r.Header.Get("X-File-Id")
	fileName := r.Header.Get("X-File-Name")

	if fileID == "" || fileName == "" {
		return "", "", fmt.Errorf("missing required headers: X-File-Id and/or X-File-Name")
	}

	return fileID, fileName, nil
}

func composeLargeFiles(ctx context.Context, bucket *storage.BucketHandle, blobs []*storage.ObjectHandle, name string) (*storage.ObjectHandle, error) {
	const maxCompose = 32
	for len(blobs) > maxCompose {
		logger.Printf("File has %d chunks, composing into %d chunks", len(blobs), len(blobs)/maxCompose)
		var tempObjects []*storage.ObjectHandle
		for i := 0; i < len(blobs); i += maxCompose {
			end := i + maxCompose
			if end > len(blobs) {
				end = len(blobs)
			}
			composedObject, err := bucket.Object(uuid.NewString()).ComposerFrom(blobs[i:end]...).Run(ctx)
			if err != nil {
				errorLogger.Printf("Error composing chunks: %v", err)
				return nil, err
			}
			tempObjects = append(tempObjects, bucket.Object(composedObject.Name))
		}
		deleteBlobs(ctx, blobs)
		blobs = tempObjects
	}

	logger.Printf("Composing %d chunks into final object", len(blobs))
	finalComposed, err := bucket.Object(name).ComposerFrom(blobs...).Run(ctx)
	if err != nil {
		errorLogger.Printf("Error composing final chunks: %v", err)
		deleteBlobs(ctx, blobs)
		return nil, err
	}
	deleteBlobs(ctx, blobs)
	return bucket.Object(finalComposed.Name), nil
}

func getAllBlobs(ctx context.Context, bucketHandle *storage.BucketHandle, prefix string) []*storage.ObjectHandle {
	var blobs []*storage.ObjectHandle
	it := bucketHandle.Objects(ctx, &storage.Query{Prefix: prefix})
	for {
		attrs, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			errorLogger.Printf("Error listing blobs: %v", err)
			continue
		}
		blobs = append(blobs, bucketHandle.Object(attrs.Name))
	}
	sort.Slice(blobs, func(i, j int) bool {
		attrsI, errI := blobs[i].Attrs(ctx)
		if errI != nil {
			errorLogger.Printf("Error getting attributes for blob: %v", errI)
			return false
		}
		attrsJ, errJ := blobs[j].Attrs(ctx)
		if errJ != nil {
			errorLogger.Printf("Error getting attributes for blob: %v", errJ)
			return false
		}
		return extractIndex(attrsI.Name) < extractIndex(attrsJ.Name)
	})
	return blobs
}

func extractIndex(blobName string) int {
	parts := strings.Split(blobName, "/")
	lastPart := parts[len(parts)-1]
	indexStr := strings.Split(lastPart, ".")[0]
	index, _ := strconv.Atoi(indexStr)
	return index
}

func deleteBlobs(ctx context.Context, blobs []*storage.ObjectHandle) error {
	for _, blob := range blobs {
		if err := blob.Delete(ctx); err != nil {
			errorLogger.Printf("Error deleting blob %s: %v", blob.ObjectName(), err)
			return err
		}
	}
	return nil
}

func moveObject(ctx context.Context, sourceBucket, destinationBucket *storage.BucketHandle, srcObjectName, destName string) error {
	src := sourceBucket.Object(srcObjectName)
	dest := destinationBucket.Object(destName).If(storage.Conditions{DoesNotExist: true})
	_, err := dest.CopierFrom(src).Run(ctx)
	if err != nil {
		errorLogger.Printf("Error copying object from %s to %s: %v", srcObjectName, destName, err)
		return err
	}
	if err := src.Delete(ctx); err != nil {
		errorLogger.Printf("Error deleting source object %s after move: %v", srcObjectName, err)
		return err
	}
	return nil
}

func checkIfBlobExists(ctx context.Context, bucket *storage.BucketHandle, blobName string) bool {
	_, err := bucket.Object(blobName).Attrs(ctx)
	return err == nil
}
