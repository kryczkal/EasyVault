import functions_framework
from google.cloud import secretmanager
import sqlalchemy

from connect_to_db import connect_to_db

@functions_framework.http
def db_setup(request):
    try:
        db = connect_to_db()
        with db.connect() as conn:
            print("Connection established")
            
            print("Executing CREATE TABLE statement...")
            conn.execute(sqlalchemy.text("""
                -- Create users table
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    google_id VARCHAR(255) UNIQUE NOT NULL,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    name VARCHAR(255)
                );

                -- Create orders table
                CREATE TABLE IF NOT EXISTS orders (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id),
                    order_date TIMESTAMP,
                    start_service TIMESTAMP,
                    end_service TIMESTAMP,
                    total_amount DECIMAL(10, 2),
                    bucket_id CHAR(40)
                );

                -- Add a check constraint to ensure end_service is after start_service
                ALTER TABLE orders ADD CONSTRAINT check_service_dates CHECK (end_service > start_service);
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