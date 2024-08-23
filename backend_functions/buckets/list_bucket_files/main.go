package function

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"cloud.google.com/go/storage"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"google.golang.org/api/iterator"
)

var (
	region    = os.Getenv("GCP_REGION")
	projectID = os.Getenv("GCP_PROJECT_ID")
)

func init() {
	if region == "" || projectID == "" {
		log.Fatalf("GCP_REGION and GCP_PROJECT_ID must be set in the environment")
	}
	functions.HTTP("ListBucketFiles", listBucketFiles)
}

type FileInfo struct {
	Name string `json:"name"`
	URL  string `json:"url"`
	Type string `json:"type"`
	Size int64  `json:"size"`
}

func listBucketFiles(w http.ResponseWriter, r *http.Request) {
	sessionID := r.URL.Query().Get("session_id")
	if sessionID == "" {
		var requestData map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&requestData); err == nil {
			if sid, ok := requestData["session_id"].(string); ok {
				sessionID = sid
			}
		}
	}

	if sessionID == "" {
		http.Error(w, "Invalid request: 'session_id' is required either as a query parameter or in the JSON body.", http.StatusBadRequest)
		return
	}

	ctx := context.Background()
	storageClient, err := storage.NewClient(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create storage client: %v", err), http.StatusInternalServerError)
		return
	}
	defer storageClient.Close()

	bucket := storageClient.Bucket(sessionID)
	it := bucket.Objects(ctx, nil)
	files := []FileInfo{}

	for {
		attrs, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			http.Error(w, fmt.Sprintf("Error listing bucket objects: %v", err), http.StatusInternalServerError)
			return
		}

		fileExtension := strings.ToLower(strings.Split(attrs.Name, ".")[len(strings.Split(attrs.Name, "."))-1])
		fileType := "other"
		if validateImage(fileExtension) {
			fileType = "image"
		} else if validateVideo(fileExtension) {
			fileType = "video"
		}

		var fileURL string
		if url, ok := attrs.Metadata["file_url"]; ok {
			expiration, _ := time.Parse(time.RFC3339, attrs.Metadata["expiration"])
			if expiration.After(time.Now()) {
				fileURL = url
			}
		}
		if fileURL == "" {
			expiration := time.Now().Add(7 * 24 * time.Hour)

			opts := &storage.SignedURLOptions{
				Scheme:  storage.SigningSchemeV4,
				Method:  "GET",
				Expires: expiration,
			}

			url, err := bucket.SignedURL(attrs.Name, opts)
			if err != nil {
				http.Error(w, fmt.Sprintf("Error generating signed URL: %v", err), http.StatusInternalServerError)
				return
			}
			fileURL = url

			attrs.Metadata = map[string]string{
				"file_url":   fileURL,
				"expiration": expiration.Format(time.RFC3339),
			}
			if _, err := bucket.Object(attrs.Name).Update(ctx, storage.ObjectAttrsToUpdate{Metadata: attrs.Metadata}); err != nil {
				http.Error(w, fmt.Sprintf("Error updating object metadata: %v", err), http.StatusInternalServerError)
				return
			}
		}

		files = append(files, FileInfo{
			Name: attrs.Name,
			URL:  fileURL,
			Type: fileType,
			Size: attrs.Size,
		})
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(files)
}

// Common image and video file extensions
var (
	IMAGE_EXTENSIONS = map[string]struct{}{
		"jpg":  {},
		"jpeg": {},
		"png":  {},
		"gif":  {},
		"bmp":  {},
		"tiff": {},
		"webp": {},
	}

	VIDEO_EXTENSIONS = map[string]struct{}{
		"mp4":  {},
		"mkv":  {},
		"avi":  {},
		"mov":  {},
		"wmv":  {},
		"flv":  {},
		"webm": {},
		"m4v":  {},
	}
)

func validateImage(extension string) bool {
	_, exists := IMAGE_EXTENSIONS[extension]
	return exists
}

func validateVideo(extension string) bool {
	_, exists := VIDEO_EXTENSIONS[extension]
	return exists
}
