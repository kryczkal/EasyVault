import datetime
import os
import functions_framework
from google.cloud import storage

from flask import jsonify, abort, make_response

from utils import validate_image, validate_video

region = os.getenv("GCP_REGION")
project_id = os.getenv("GCP_PROJECT_ID")
if not all([region, project_id]):
    raise ValueError("GCP_REGION and GCP_PROJECT_ID must be set in the environment")

@functions_framework.http
def list_bucket_files_3(request):
    try:
        session_id = request.args.get('session_id')

        if not session_id:
            request_json = request.get_json(silent=True)
            if request_json and 'session_id' in request_json:
                session_id = request_json['session_id']

        if not session_id:
            return abort(400, description="Invalid request: 'session_id' is required either as a query parameter or in the JSON body.")
        
        base_url = f"https://{region}-{project_id}.cloudfunctions.net/"
        proxy_base_url = f"{base_url}proxy-file"

        storage_client = storage.Client()
        bucket = storage_client.get_bucket(session_id)
        print(f"Bucket {session_id} found")
        print(f"Number of files in bucket: {len(list(bucket.list_blobs()))}")

        files = []
        for blob in bucket.list_blobs():
            file_extension = blob.name.split('.')[-1].lower()
            if validate_image(file_extension):
                file_type = "image"
            elif validate_video(file_extension):
                file_type = "video"
            else:
                file_type = "other"

            if blob.metadata and blob.metadata.get("file_url") and blob.metadata.get("expiration").isoformat() > datetime.datetime.now().isoformat():
                file_url = blob.metadata["file_url"]
            else:
                expiration = datetime.datetime.now() + datetime.timedelta(days=7)
                file_url = blob.generate_signed_url(
                    expiration=expiration,
                    method="GET",
                    version="v4",
                    virtual_hosted_style=True,
                )
                if blob.metadata is None:
                    blob.metadata = {"file_url": file_url, "expiration": expiration.isoformat()}
                else:
                    blob.metadata["file_url"] = file_url
                    blob.metadata["expiration"] = expiration.isoformat()
                blob.patch()

            file_info = {
                "name": blob.name,
                "url": file_url,
                "type": file_type,
                "size": blob.size,
            }
            files.append(file_info)
        
        response = make_response(jsonify(files), 200)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type"

        return response
    
    except Exception as e:
        response = make_response(
            jsonify({"error": f"An error occurred: {str(e)}"}), 500
        )
        response.headers["Access-Control-Allow-Origin"] = "*"
        return response
