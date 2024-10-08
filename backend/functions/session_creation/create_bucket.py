from google.cloud import storage

def create_bucket(id : str):
    bucket_name = f'{id}'

    storage_client = storage.Client()
    bucket = storage_client.create_bucket(bucket_name, location='EUROPE-CENTRAL2')

    bucket.iam_configuration.uniform_bucket_level_access_enabled = False
    bucket.make_public(recursive=True, future=True)
    bucket.make_private(recursive=False)
    bucket.cors = [
        {
            "origin": ["*"],
            "responseHeader": [
                "*",
            ],
            "method": ['GET','PUT', 'POST'],
            "maxAgeSeconds": 3600
        }
    ]
    bucket.patch()
    bucket.update()

    file_upload_bucket = storage_client.create_bucket(f'file-chunks-{id}', location='EUROPE-CENTRAL2')
    file_upload_bucket.iam_configuration.uniform_bucket_level_access_enabled = False
    file_upload_bucket.add_lifecycle_delete_rule(age=1)
    file_upload_bucket.cors = [
        {
            "origin": ["*"],
            "responseHeader": [
                "*",
            ],
            "method": ['GET','PUT', 'POST'],
            "maxAgeSeconds": 3600
        }
    ]
    file_upload_bucket.patch()
    file_upload_bucket.update()

    return f'Bucket {bucket.name} created.'
