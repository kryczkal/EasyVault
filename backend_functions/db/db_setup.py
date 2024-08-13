import os
import functions_framework
from google.cloud import secretmanager
import sqlalchemy

def access_secret_version(secret_name):
    client = secretmanager.SecretManagerServiceClient()
    response = client.access_secret_version(request={"name": f"{secret_name}/versions/latest"})
    return response.payload.data.decode("UTF-8")

@functions_framework.http
def setup_database(request):
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

    print("Connection pool created successfully")

    # Create tables
    try:
        with db.connect() as conn:
            print("Connection established")
            
            print("Executing CREATE TABLE statement...")
            conn.execute(sqlalchemy.text("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(120) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """))
            print("CREATE TABLE statement executed")
            
            print("Committing transaction...")
            conn.commit()
            print("Transaction committed")

        return 'Database setup completed successfully'
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500