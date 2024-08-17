import functions_framework
from google.cloud import storage
from flask import jsonify, abort, make_response, send_file

@functions_framework.http
def proxy_file(request):
    try:
        # Extract parameters from request
        bucket_id = request.args.get('bucket_id')
        file_name = request.args.get('file_name')

        if not bucket_id or not file_name:
            request_json = request.get_json(silent=True)
            if request_json:
                bucket_id = request_json.get('bucket_id', bucket_id)
                file_name = request_json.get('file_name', file_name)

        if not bucket_id or not file_name:
            return abort(400, description="Invalid request: 'bucket_id' and 'file_name' are required either as query parameters or in the JSON body.")

        # Initialize Cloud Storage client and get the bucket
        storage_client = storage.Client()
        bucket = storage_client.get_bucket(bucket_id)

        # Get the blob (file) from the bucket
        blob = bucket.blob(file_name)
        if not blob.exists():
            return abort(404, description=f"File {file_name} not found in bucket {bucket_id}.")

        # Download the file content into memory
        file_content = blob.download_as_bytes()

        # Serve the file
        response = make_response(file_content)
        response.headers["Content-Disposition"] = f"attachment; filename={file_name}"
        response.headers["Content-Type"] = blob.content_type or "application/octet-stream"
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
