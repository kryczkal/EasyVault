import functions_framework
import os
from flask import request, jsonify, make_response
from google.cloud import storage
import logging

storage_client = storage.Client()
BUCKET_NAME = os.getenv('BUCKET_NAME', 'file-chunks-')

@functions_framework.http
def upload_chunk(request):
    if request.method == 'OPTIONS':
            response = make_response('', 204)
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
            return response

    try:
        # Step 1: Extracting the session_id
        bucket_id = request.args.get('session_id')

        if not bucket_id:
            request_json = request.get_json(silent=True)
            if request_json and 'session_id' in request_json:
                bucket_id = request_json['session_id']

        if not bucket_id:
            response = jsonify({'error': 'Invalid request: \'session_id\' is required either as a query parameter or in the JSON body.'})
            response.status_code = 400
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
            return response

        logging.info(f"Uploading chunk to bucket {bucket_id}")

        # Step 2: Extracting required headers
        file_id = request.headers.get('X-File-Id')
        chunk_index = request.headers.get('X-Chunk-Index')
        total_chunks = request.headers.get('X-Total-Chunks')

        logging.info(f"File ID: {file_id}, Chunk Index: {chunk_index}, Total Chunks: {total_chunks}")

        # Step 3: Validate required headers
        if not all([file_id, chunk_index, total_chunks]):
            response = jsonify({'error': 'Missing required headers: X-File-Id, X-Chunk-Index, X-Total-Chunks'})
            response.status_code = 400
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
            return response

        try:
            chunk_index = int(chunk_index)
            total_chunks = int(total_chunks)
        except ValueError:
            response = jsonify({'error': 'Invalid chunk index or total chunks. They must be integers.'})
            response.status_code = 400
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
            return response

        # Step 4: Interacting with cloud storage
        try:
            bucket = storage_client.get_bucket(f"{BUCKET_NAME}{bucket_id}")
        except Exception as e:
            logging.error(f"Error accessing bucket {bucket_id}: {str(e)}")
            response = jsonify({'error': f'Error accessing bucket: {str(e)}'})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
            return response

        try:
            blob = bucket.blob(f'{file_id}/{chunk_index}.chunk')
            logging.info(f"Uploading to blob {blob.name}")
            blob.upload_from_string(request.data)
        except Exception as e:
            logging.error(f"Error uploading chunk to blob {blob.name}: {str(e)}")
            response = jsonify({'error': f'Error uploading chunk: {str(e)}'})
            response.status_code = 500
            response.headers["Access-Control-Allow-Origin"] = "*"
            return response

        response = jsonify({'message': 'Chunk uploaded successfully'})
        response.status_code = 200
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
        return response

    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        response = jsonify({'error': f'Unexpected error occurred: {str(e)}'})
        response.status_code = 500
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, X-File-Id, X-Chunk-Index, X-Total-Chunks"
        return response
