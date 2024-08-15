import functions_framework
from google.cloud import storage
from flask import jsonify, abort

@functions_framework.http
def list_bucket_files(request):
    try:
        request_json = request.get_json(silent=True)
        if not request_json or 'bucket_id' not in request_json:
            return abort(400, description="Invalid request: 'bucket_id' is required.")
        
        bucket_id = request_json['bucket_id']
        
        storage_client = storage.Client()
        bucket = storage_client.get_bucket(bucket_id)
        print(f"Bucket {bucket_id} found")
        print(f"Number of files in bucket: {len(list(bucket.list_blobs()))}")
        
        files = []
        for blob in bucket.list_blobs():
            file_info = {
                "name": blob.name,
                "url": blob.public_url
            }
            files.append(file_info)
        
        return jsonify(files), 200
    
    except Exception as e:
        return abort(500, description=f"An error occurred: {str(e)}")
