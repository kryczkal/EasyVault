import os
from google.cloud import secretmanager
import sqlalchemy

def access_secret_version(secret_name) -> str:
    client = secretmanager.SecretManagerServiceClient()
    response = client.access_secret_version(request={"name": f"{secret_name}/versions/latest"})
    return response.payload.data.decode("UTF-8")

def connect_to_db() -> sqlalchemy.engine.base.Connection:
    db_user = access_secret_version(os.environ.get("DB_USER"))
    db_pass = access_secret_version(os.environ.get("DB_PASSWORD"))
    db_name = access_secret_version(os.environ.get("DB_NAME"))
    db_connection_name = access_secret_version(os.environ.get("DB_CONNECTION_NAME"))

    db = sqlalchemy.create_engine(
        sqlalchemy.engine.url.URL.create(
            drivername="postgresql+pg8000",
            username=db_user,
            password=db_pass,
            database=db_name,
            query={
                "unix_sock": f"/cloudsql/{db_connection_name}/.s.PGSQL.5432"
            }
        ),
    )

    return db