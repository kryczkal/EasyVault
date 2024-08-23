package function

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"

	"cloud.google.com/go/storage"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/google/uuid"
	"google.golang.org/api/iterator"
)

var (
	storageClient *storage.Client
	bucketName    string
)

func init() {
	ctx := context.Background()
	var err error
	storageClient, err = storage.NewClient(ctx)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	bucketName = os.Getenv("BUCKET_NAME")
	if bucketName == "" {
		bucketName = "file-chunks-"
	}
	functions.HTTP("UploadFinalize", uploadFinalize)
}

func uploadFinalize(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-File-Id, X-File-Name")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	ctx := r.Context()
	sessionID := r.URL.Query().Get("session_id")
	if sessionID == "" {
		decoder := json.NewDecoder(r.Body)
		var data map[string]interface{}
		if err := decoder.Decode(&data); err == nil {
			if val, ok := data["session_id"].(string); ok {
				sessionID = val
			}
		}
	}

	if sessionID == "" {
		http.Error(w, "Invalid request: 'session_id' is required either as a query parameter or in the JSON body.", http.StatusBadRequest)
		return
	}

	log.Printf("Finalizing upload to bucket %s", sessionID)

	fileID := r.Header.Get("X-File-Id")
	fileName := r.Header.Get("X-File-Name")

	if fileID == "" || fileName == "" {
		http.Error(w, "Missing required headers: X-File-Id and/or X-File-Name", http.StatusBadRequest)
		return
	}

	log.Printf("fileID: %s, fileName: %s", fileID, fileName)

	sourceBucket := storageClient.Bucket(bucketName + sessionID)
	if _, err := sourceBucket.Attrs(ctx); err != nil {
		http.Error(w, "Failed to get source bucket: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Source bucket: %s", sourceBucket)

	blobs := getAllBlobs(ctx, sourceBucket, fileID)
	if len(blobs) == 0 {
		http.Error(w, "No file found", http.StatusNotFound)
		return
	}
	log.Printf("Found %d chunks", len(blobs))

	destinationBucket := storageClient.Bucket(sessionID)
	if _, err := destinationBucket.Attrs(ctx); err != nil {
		http.Error(w, "Failed to get destination bucket: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Destination bucket: %s", destinationBucket)

	fileNameSplitted := strings.Split(fileName, ".")
	fileName = fileNameSplitted[0] + "-" + uuid.NewString() + "." + fileNameSplitted[1]

	if checkIfBlobExists(ctx, destinationBucket, fileName) {
		http.Error(w, "File already exists", http.StatusConflict)
		return
	}
	log.Printf("File does not exist in destination bucket")

	finalObject, err := composeLargeFiles(ctx, sourceBucket, blobs, fileName)
	if err != nil {
		http.Error(w, "Error during large file composition: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Print("File composed successfully")

	finalObjectAttrs, err := finalObject.Attrs(ctx)
	if err != nil {
		http.Error(w, "Failed to get attributes of composed object: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Final composed object attributes: %v", finalObjectAttrs)

	if err := moveObject(ctx, sourceBucket, destinationBucket, finalObjectAttrs.Name, fileName); err != nil {
		http.Error(w, "Error moving final composed object: "+err.Error(), http.StatusInternalServerError)
		return
	}
	log.Printf("Final composed object moved to destination bucket")

	response := map[string]string{"message": "File composed successfully into " + finalObjectAttrs.Name}
	jsonResponse, _ := json.Marshal(response)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(jsonResponse)
}

func composeLargeFiles(ctx context.Context, bucket *storage.BucketHandle, blobs []*storage.ObjectHandle, name string) (*storage.ObjectHandle, error) {
	const maxCompose = 32
	for len(blobs) > maxCompose {
		log.Printf("File has %d chunks, composing into %d chunks", len(blobs), len(blobs)/maxCompose)
		var tempObjects []*storage.ObjectHandle
		for i := 0; i < len(blobs); i += maxCompose {
			end := i + maxCompose
			if end > len(blobs) {
				end = len(blobs)
			}
			composedObject, err := bucket.Object(uuid.NewString()).ComposerFrom(blobs[i:end]...).Run(ctx)
			if err != nil {
				return nil, err
			}
			tempObjects = append(tempObjects, bucket.Object(composedObject.Name))
		}
		deleteBlobs(ctx, blobs)
		blobs = tempObjects
	}

	log.Printf("Composing %d chunks into final object", len(blobs))
	finalComposed, err := bucket.Object(name).ComposerFrom(blobs...).Run(ctx)
	if err != nil {
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
			log.Printf("Error listing blobs: %v", err)
			continue
		}
		blobs = append(blobs, bucketHandle.Object(attrs.Name))
	}
	sort.Slice(blobs, func(i, j int) bool {
		attrsI, errI := blobs[i].Attrs(ctx)
		if errI != nil {
			log.Printf("Error getting attributes for blob: %v", errI)
			return false
		}
		attrsJ, errJ := blobs[j].Attrs(ctx)
		if errJ != nil {
			log.Printf("Error getting attributes for blob: %v", errJ)
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
		return err
	}
	return src.Delete(ctx)
}

// Returns true if the blob exists, false otherwise
func checkIfBlobExists(ctx context.Context, bucket *storage.BucketHandle, blobName string) bool {
	_, err := bucket.Object(blobName).Attrs(ctx)
	return err == nil
}
