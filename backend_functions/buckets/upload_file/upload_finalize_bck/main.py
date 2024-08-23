import functions_framework
import os
from flask import request, jsonify, make_response
from google.cloud import storage
import logging

storage_client = storage.Client()
BUCKET_NAME = os.getenv('BUCKET_NAME', 'file-chunks-')

@functions_framework.http
def upload_finalize(request):
    # Handle CORS preflight request
    if request.method == 'OPTIONS':
        response = make_response('', 204)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return response

    try:
        # Step 1: Extract session_id
        bucket_id = request.args.get('session_id')

        if not bucket_id:
            request_json = request.get_json(silent=True)
            if request_json and 'session_id' in request_json:
                bucket_id = request_json['session_id']

        if not bucket_id:
            response = jsonify({'error': "Invalid request: 'session_id' is required either as a query parameter or in the JSON body."})
            response.status_code = 400
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        logging.info(f"Finalizing upload to bucket {bucket_id}")

        # Step 2: Extract fileId
        file_id = request.json.get('fileId')
        file_name = request.json.get('fileName')
        if not all([file_id, file_name]):
            response = jsonify({'error': "Missing required fields: fileId, fileName"})
            response.status_code = 400
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        logging.info(f"File ID: {file_id}")
        logging.info(f"File Name: {file_name}")

        # Step 3: Retrieve source bucket and list blobs
        try:
            source_bucket = storage_client.get_bucket(f"{BUCKET_NAME}{bucket_id}")
        except Exception as e:
            logging.error(f"Error accessing source bucket {BUCKET_NAME}{bucket_id}: {str(e)}")
            response = jsonify({'error': f"Error accessing source bucket: {str(e)}"})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        blobs = list(source_bucket.list_blobs(prefix=file_id))

        logging.info(f"Number of chunks found: {len(blobs)}")

        if len(blobs) == 0:
            response = jsonify({'error': "No file found"})
            response.status_code = 404
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        # Step 4: Reassemble the file
        file_path = f'/tmp/{file_id}'
        try:
            with open(file_path, 'wb') as file:
                for blob in sorted(blobs, key=lambda b: int(b.name.split('/')[-1].split('.')[0])):
                    file.write(blob.download_as_bytes())

            logging.info(f"File reassembled {file_id}, name: {file_name}")
        except Exception as e:
            logging.error(f"Error reassembling file {file_name}: {str(e)}")
            response = jsonify({'error': f"Error reassembling file: {str(e)}"})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        # Step 5: Upload the reassembled file to the destination bucket
        try:
            destination_bucket = storage_client.get_bucket(bucket_id)
            final_blob = destination_bucket.blob(f'{file_name}')
            final_blob.upload_from_filename(file_path)

            logging.info(f"File uploaded to {final_blob.name}")
        except Exception as e:
            logging.error(f"Error uploading final file to bucket {bucket_id}: {str(e)}")
            response = jsonify({'error': f"Error uploading final file: {str(e)}"})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        # Step 6: Clean up chunks and temporary file
        try:
            for blob in blobs:
                blob.delete()

            logging.info("Chunks deleted")
        except Exception as e:
            logging.error(f"Error deleting chunks for file {file_name}: {str(e)}")
            response = jsonify({'error': f"Error deleting chunks: {str(e)}"})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        try:
            os.remove(file_path)
            logging.info("Temporary file deleted")
        except Exception as e:
            logging.error(f"Error deleting temporary file {file_path}: {str(e)}")
            response = jsonify({'error': f"Error deleting temporary file: {str(e)}"})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type"
            return response

        response = jsonify({'message': "File uploaded successfully"})
        response.status_code = 200
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return response

    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        response = jsonify({'error': f"Unexpected error occurred: {str(e)}"})
        response.status_code = 500
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return response
