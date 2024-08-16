from google.cloud import storage

def delete_bucket(id : str):
    bucket_name = f'{id}'
 
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    bucket.delete()

    bucket = storage_client.get_bucket(f'file-chunks-{id}')
    bucket.delete()

    return f'Bucket {bucket.name} deleted.'
    