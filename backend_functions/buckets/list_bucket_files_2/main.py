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
def list_bucket_files_2(request):
    try:
        bucket_id = request.args.get('bucket_id')

        if not bucket_id:
            request_json = request.get_json(silent=True)
            if request_json and 'bucket_id' in request_json:
                bucket_id = request_json['bucket_id']

        if not bucket_id:
            return abort(400, description="Invalid request: 'bucket_id' is required either as a query parameter or in the JSON body.")
        
        base_url = f"https://{region}-{project_id}.cloudfunctions.net/"
        proxy_base_url = f"{base_url}proxy-file"

        storage_client = storage.Client()
        bucket = storage_client.get_bucket(bucket_id)
        print(f"Bucket {bucket_id} found")
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

            # Generate proxy URL for the file
            file_url = f"{proxy_base_url}?bucket_id={bucket_id}&file_name={blob.name}"

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
