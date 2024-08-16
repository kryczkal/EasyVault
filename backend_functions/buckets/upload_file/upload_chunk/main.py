import functions_framework
import os
from flask import request, jsonify, abort
from google.cloud import storage
import logging

storage_client = storage.Client()
BUCKET_NAME = os.getenv('BUCKET_NAME', 'file-chunks-')

@functions_framework.http
def upload_chunk(request):
    try:
        # Step 1: Extracting the session_id
        bucket_id = request.args.get('session_id')

        if not bucket_id:
            request_json = request.get_json(silent=True)
            if request_json and 'session_id' in request_json:
                bucket_id = request_json['session_id']

        if not bucket_id:
            return jsonify({'error': 'Invalid request: \'session_id\' is required either as a query parameter or in the JSON body.'}), 400

        logging.info(f"Uploading chunk to bucket {bucket_id}")

        # Step 2: Extracting required headers
        file_id = request.headers.get('X-File-Id')
        chunk_index = request.headers.get('X-Chunk-Index')
        total_chunks = request.headers.get('X-Total-Chunks')

        logging.info(f"File ID: {file_id}, Chunk Index: {chunk_index}, Total Chunks: {total_chunks}")

        # Step 3: Validate required headers
        if not file_id or chunk_index is None or total_chunks is None:
            return jsonify({'error': 'Missing required headers: X-File-Id, X-Chunk-Index, X-Total-Chunks'}), 400

        try:
            chunk_index = int(chunk_index)
            total_chunks = int(total_chunks)
        except ValueError:
            return jsonify({'error': 'Invalid chunk index or total chunks. They must be integers.'}), 400

        # Step 4: Interacting with cloud storage
        try:
            bucket = storage.Client().get_bucket(f"{BUCKET_NAME}{bucket_id}")
        except Exception as e:
            logging.error(f"Error accessing bucket {bucket_id}: {str(e)}")
            return jsonify({'error': f'Error accessing bucket: {str(e)}'}), 500

        try:
            blob = bucket.blob(f'{file_id}/{chunk_index}.chunk')
            logging.info(f"Uploading to blob {blob.name}")
            blob.upload_from_string(request.data)
        except Exception as e:
            logging.error(f"Error uploading chunk to blob {blob.name}: {str(e)}")
            return jsonify({'error': f'Error uploading chunk: {str(e)}'}), 500

        return jsonify({'message': 'Chunk uploaded successfully'}), 200

    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': f'Unexpected error occurred: {str(e)}'}), 500