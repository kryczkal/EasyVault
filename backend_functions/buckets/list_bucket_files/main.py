import functions_framework
from google.cloud import storage
from flask import jsonify, abort, make_response

from utils import validate_image, validate_video

@functions_framework.http
def list_bucket_files(request):
    try:
        session_id = request.args.get('session_id')

        if not session_id:
            request_json = request.get_json(silent=True)
            if request_json and 'session_id' in request_json:
                session_id = request_json['session_id']

        if not session_id:
            return abort(400, description="Invalid request: 'session_id' is required either as a query parameter or in the JSON body.")
        
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

            file_info = {
                "name": blob.name,
                "url": blob.public_url,
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
