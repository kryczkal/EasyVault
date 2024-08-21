package function

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

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
	functions.HTTP("ClearSignedURLs", clearSignedURLs)
}

func clearSignedURLs(w http.ResponseWriter, r *http.Request) {
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

	for {
		attrs, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			http.Error(w, fmt.Sprintf("Error listing bucket objects: %v", err), http.StatusInternalServerError)
			return
		}

		delete(attrs.Metadata, "file_url")
		delete(attrs.Metadata, "expiration")

		if _, err := bucket.Object(attrs.Name).Update(ctx, storage.ObjectAttrsToUpdate{Metadata: attrs.Metadata}); err != nil {
			http.Error(w, fmt.Sprintf("Error updating object metadata: %v", err), http.StatusInternalServerError)
			return
		}
	}

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Signed URLs cleared for all objects in bucket: %s", sessionID)
}
