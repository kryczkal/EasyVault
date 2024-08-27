import os
import sqlalchemy

def connect_to_db() -> sqlalchemy.engine.base.Connection:
    db_user = os.environ.get("DB_USER")
    db_pass = os.environ.get("DB_PASSWORD")
    db_name = os.environ.get("DB_NAME")
    db_connection_name = os.environ.get("DB_CONNECTION_NAME")

    if not all([db_user, db_pass, db_name, db_connection_name]):
        raise ValueError("Missing required environment variables")

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

    if db is None:
        raise ValueError("Database connection failed")

    return db