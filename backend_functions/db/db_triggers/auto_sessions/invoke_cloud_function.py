import os
import requests

import google.auth.transport.requests
import google.oauth2.id_token

def invoke_cloud_function(function_name, data, headers=None) -> requests.Response:
    region = os.getenv("GCP_REGION")
    project_id = os.getenv("GCP_PROJECT_ID")
    if not all([region, project_id]):
        raise ValueError("GCP_REGION and GCP_PROJECT_ID must be set in the environment")



    base_url = f"https://{region}-{project_id}.cloudfunctions.net/"
    function_url = f"{base_url}{function_name}"

    auth_req = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, function_url)

    print(f"ID toke for audience {function_url}: {id_token}")
    print(f"Function URL: {function_url}")

    if headers is None:
        headers = {}
        headers["Authorization"] = f"Bearer {id_token}"
    else:
        headers["Authorization"] = f"Bearer {id_token}"

    print(f"Invoking cloud function: {function_url}")

    return requests.post(function_url, json=data, headers=headers)
