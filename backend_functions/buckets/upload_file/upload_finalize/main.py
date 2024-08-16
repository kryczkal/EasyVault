import functions_framework
import os
from flask import request, jsonify
from google.cloud import storage
import logging

storage_client = storage.Client()
BUCKET_NAME = os.getenv('BUCKET_NAME', 'file-chunks-')

@functions_framework.http
def upload_finalize(request):
    try:
        # Step 1: Extract session_id
        bucket_id = request.args.get('session_id')

        if not bucket_id:
            request_json = request.get_json(silent=True)
            if request_json and 'session_id' in request_json:
                bucket_id = request_json['session_id']

        if not bucket_id:
            return jsonify({'error': "Invalid request: 'session_id' is required either as a query parameter or in the JSON body."}), 400

        logging.info(f"Finalizing upload to bucket {bucket_id}")

        # Step 2: Extract fileId
        file_id = request.json.get('fileId')
        if not file_id:
            return jsonify({'error': "Missing fileId"}), 400

        logging.info(f"File ID: {file_id}")

        # Step 3: Retrieve source bucket and list blobs
        try:
            source_bucket = storage_client.get_bucket(f"{BUCKET_NAME}{bucket_id}")
        except Exception as e:
            logging.error(f"Error accessing source bucket {BUCKET_NAME}{bucket_id}: {str(e)}")
            return jsonify({'error': f"Error accessing source bucket: {str(e)}"}), 500

        blobs = list(source_bucket.list_blobs(prefix=file_id))

        logging.info(f"Number of chunks found: {len(blobs)}")

        if len(blobs) == 0:
            return jsonify({'error': "No file found"}), 404

        # Step 4: Reassemble the file
        file_path = f'/tmp/{file_id}'
        try:
            with open(file_path, 'wb') as file:
                for blob in sorted(blobs, key=lambda b: int(b.name.split('/')[-1].split('.')[0])):
                    file.write(blob.download_as_bytes())

            logging.info(f"File reassembled: {file_path}")
        except Exception as e:
            logging.error(f"Error reassembling file {file_id}: {str(e)}")
            return jsonify({'error': f"Error reassembling file: {str(e)}"}), 500

        # Step 5: Upload the reassembled file to the destination bucket
        try:
            destination_bucket = storage_client.get_bucket(bucket_id)
            final_blob = destination_bucket.blob(f'{file_id}')
            final_blob.upload_from_filename(file_path)

            logging.info(f"File uploaded to {final_blob.name}")
        except Exception as e:
            logging.error(f"Error uploading final file to bucket {bucket_id}: {str(e)}")
            return jsonify({'error': f"Error uploading final file: {str(e)}"}), 500

        # Step 6: Clean up chunks and temporary file
        try:
            for blob in blobs:
                blob.delete()

            logging.info("Chunks deleted")
        except Exception as e:
            logging.error(f"Error deleting chunks for file {file_id}: {str(e)}")
            return jsonify({'error': f"Error deleting chunks: {str(e)}"}), 500

        try:
            os.remove(file_path)
            logging.info("Temporary file deleted")
        except Exception as e:
            logging.error(f"Error deleting temporary file {file_path}: {str(e)}")
            return jsonify({'error': f"Error deleting temporary file: {str(e)}"}), 500

        return jsonify({'message': "File uploaded successfully"}), 200

    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': f"Unexpected error occurred: {str(e)}"}), 500