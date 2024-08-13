import functions_framework
from google.cloud import storage

@functions_framework.http
def create_bucket(request):
    request_json = request.get_json(silent=True)
    uuid = request_json['uuid']
    
    bucket_name = f'event-bucket-{uuid}'
    
    storage_client = storage.Client()
    bucket = storage_client.create_bucket(bucket_name, location='EUROPE-CENTRAL2')
    
    return f'Bucket {bucket.name} created.'