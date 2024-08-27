package function

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"

	"cloud.google.com/go/logging"
	"cloud.google.com/go/storage"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

type ChunkInfo struct {
	FileID      string `json:"file_id"`
	ChunkIndex  int    `json:"chunk_index"`
	TotalChunks int    `json:"total_chunks"`
}

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

	logName := "upload-chunk"
	logger = client.Logger(logName).StandardLogger(logging.Info)
	warningLogger = client.Logger(logName).StandardLogger(logging.Warning)
	errorLogger = client.Logger(logName).StandardLogger(logging.Error)

	functions.HTTP("UploadChunk", uploadChunk)
}

func uploadChunk(w http.ResponseWriter, r *http.Request) {
	writeHeaders(w)

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusNoContent)
		return
	}


	ctx := r.Context()
	sessionID, err := getSessionID(r)
	if err != nil {
		warningLogger.Printf("Failed to get session ID: %v", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	chunkInfo, err := getChunkInfo(r)
	if err != nil {
		warningLogger.Printf("Invalid headers: %v", err)
		http.Error(w, fmt.Sprintf("Invalid headers: %v", err), http.StatusBadRequest)
		return
	}

	err = handleFileUpload(ctx, sessionID, chunkInfo, r.Body)
	if err != nil {
		errorLogger.Printf("Failed to upload file chunk: %v", err)
		http.Error(w, fmt.Sprintf("Failed to upload chunk: %v", err), http.StatusInternalServerError)
		return
	}

	logger.Printf("Successfully uploaded chunk: %d/%d for file %s", chunkInfo.ChunkIndex, chunkInfo.TotalChunks, chunkInfo.FileID)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Chunk uploaded successfully"})
}

func writeHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks")
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

func getChunkInfo(r *http.Request) (ChunkInfo, error) {
	fileID := r.Header.Get("X-File-ID")
	chunkIndex := r.Header.Get("X-Chunk-Index")
	totalChunks := r.Header.Get("X-Total-Chunks")

	if fileID == "" || chunkIndex == "" || totalChunks == "" {
		return ChunkInfo{}, fmt.Errorf("missing required headers: X-File-ID, X-Chunk-Index, X-Total-Chunks")
	}

	ci := ChunkInfo{FileID: fileID}
	var err error
	ci.ChunkIndex, err = strconv.Atoi(chunkIndex)
	if err != nil {
		return ChunkInfo{}, fmt.Errorf("chunk index must be an integer")
	}
	ci.TotalChunks, err = strconv.Atoi(totalChunks)
	if err != nil {
		return ChunkInfo{}, fmt.Errorf("total chunks must be an integer")
	}
	return ci, nil
}

func handleFileUpload(ctx context.Context, sessionID string, info ChunkInfo, data io.Reader) error {
	bucket := storageClient.Bucket(fmt.Sprintf("%s%s", bucketName, sessionID))
	object := bucket.Object(fmt.Sprintf("%s/%d.chunk", info.FileID, info.ChunkIndex))

	w := object.NewWriter(ctx)
	if _, err := io.Copy(w, data); err != nil {
		return fmt.Errorf("failed to write to object: %v", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("failed to close writer: %v", err)
	}
	return nil
}
