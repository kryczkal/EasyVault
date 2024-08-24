package function

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"google.golang.org/api/idtoken"
)

func InvokeCloudFunction(functionName string, data interface{}) (*http.Response, error) {
	region := os.Getenv("GCP_REGION")
	projectID := os.Getenv("GCP_PROJECT_ID")
	if region == "" || projectID == "" {
		return nil, fmt.Errorf("GCP_REGION and GCP_PROJECT_ID must be set in the environment")
	}

	functionURL := fmt.Sprintf("https://%s-%s.cloudfunctions.net/%s", region, projectID, functionName)
	log.Print("Invoking function: ", functionURL)

	ctx := context.Background()
	client, err := idtoken.NewClient(ctx, functionURL)
	if err != nil {
		return nil, fmt.Errorf("failed to create idtoken client: %v", err)
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		return nil, fmt.Errorf("error marshalling data: %v", err)
	}
	log.Print("Data: ", string(jsonData))

	req, err := http.NewRequest("POST", functionURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Add("Content-Type", "application/json")
	tokenSource, err := idtoken.NewTokenSource(ctx, functionURL)
	if err != nil {
		return nil, fmt.Errorf("failed to obtain token source: %v", err)
	}

	idToken, err := tokenSource.Token()
	if err != nil {
		return nil, fmt.Errorf("failed to obtain ID token: %v", err)
	}

	req.Header.Add("Authorization", "Bearer "+idToken.AccessToken)

	return client.Do(req)
}
