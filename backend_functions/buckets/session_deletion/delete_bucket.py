from google.cloud import storage
from google.cloud.exceptions import NotFound

def delete_bucket(id: str):
    bucket_names = [f'{id}', f'file-chunks-{id}']
    
    storage_client = storage.Client()
    
    for bucket_name in bucket_names:
        try:
            bucket = storage_client.get_bucket(bucket_name)
            bucket.delete()
            print(f'Bucket {bucket_name} deleted.')
        except NotFound:
            print(f'Bucket {bucket_name} not found, skipping deletion.')

    return "Operation completed."

