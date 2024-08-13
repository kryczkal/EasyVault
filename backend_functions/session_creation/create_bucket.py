from google.cloud import storage

def create_bucket(id : str):
    bucket_name = f'{id}'
    
    storage_client = storage.Client()
    bucket = storage_client.create_bucket(bucket_name, location='EUROPE-CENTRAL2')
    
    return f'Bucket {bucket.name} created.'