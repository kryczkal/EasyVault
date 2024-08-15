from google.cloud import storage

def create_bucket(id : str):
    bucket_name = f'{id}'
    
    storage_client = storage.Client()
    bucket = storage_client.create_bucket(bucket_name, location='EUROPE-CENTRAL2')

    bucket.iam_configuration.uniform_bucket_level_access_enabled = False
    bucket.make_public(recursive=True, future=True)
    bucket.make_private(recursive=False)
    bucket.update()
    
    return f'Bucket {bucket.name} created.'