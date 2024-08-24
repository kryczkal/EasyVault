package function

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

// FileInfo from the library
type FileInfo struct {
	Name string `json:"name"`
	URL  string `json:"url"`
	Type string `json:"type"`
	Size int64  `json:"size"`
}

var (
	region        = os.Getenv("GCP_REGION")
	projectID     = os.Getenv("GCP_PROJECT_ID")
	listFilesName = os.Getenv("GCF_LIST_BUCKET_FILES_NAME")
)

func init() {
	if region == "" || projectID == "" || listFilesName == "" {
		log.Fatalf("GCP_REGION, GCP_PROJECT_ID, and GCF_LIST_BUCKET_FILES_NAME must be set in the environment")
	}
	functions.HTTP("DownloadAllFiles", downloadAllFiles)
}

func downloadAllFiles(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/zip")
	w.Header().Set("Content-Disposition", "attachment; filename=\"download.zip\"")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusNoContent)
		return
	}

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
	log.Print("Session ID: ", sessionID)

	files, err := initializeFileList(sessionID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error retrieving files: %v", err), http.StatusInternalServerError)
		return
	}

	zipWriter := zip.NewWriter(w)
	defer zipWriter.Close()

	for _, file := range files {
		err := addFileToZip(zipWriter, file)
		if err != nil {
			log.Printf("Failed to add file %s to zip: %v", file.Name, err)
			continue
		}
	}
}

func addFileToZip(zipWriter *zip.Writer, file FileInfo) error {
	resp, err := http.Get(file.URL)
	if err != nil {
		return fmt.Errorf("failed to download file %s: %v", file.Name, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to download file %s: status code %d", file.Name, resp.StatusCode)
	}

	zipFile, err := zipWriter.Create(file.Name)
	if err != nil {
		return fmt.Errorf("failed to create zip entry for file %s: %v", file.Name, err)
	}

	_, err = io.Copy(zipFile, resp.Body)
	if err != nil {
		return fmt.Errorf("failed to write file %s to zip: %v", file.Name, err)
	}

	return nil
}

func initializeFileList(sessionID string) ([]FileInfo, error) {
	requestData := map[string]interface{}{
		"session_id": sessionID,
	}

	resp, err := InvokeCloudFunction(listFilesName, requestData)
	if err != nil {
		return nil, fmt.Errorf("error invoking cloud function: %v", err)
	}
	log.Print("Response: ", resp)

	var files []FileInfo
	if err := json.NewDecoder(resp.Body).Decode(&files); err != nil {
		return nil, fmt.Errorf("error decoding response: %v", err)
	}

	return files, nil
}
