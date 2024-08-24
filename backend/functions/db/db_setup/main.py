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
                CREATE TYPE order_status AS ENUM ('pending', 'active', 'completed', 'canceled');

                -- Users table
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    google_id VARCHAR(255) UNIQUE NOT NULL,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    name VARCHAR(255),
                    CONSTRAINT check_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}$')
                );

                -- Orders table
                CREATE TABLE IF NOT EXISTS orders (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    order_date TIMESTAMPTZ DEFAULT NOW(),
                    start_service TIMESTAMPTZ NOT NULL,
                    end_service TIMESTAMPTZ NOT NULL,
                    status order_status DEFAULT 'pending',
                    total_amount DECIMAL(10, 2) CHECK (total_amount >= 0),
                    bucket_id CHAR(40),
                    CONSTRAINT check_service_dates CHECK (end_service > start_service)
                );

                -- Indexes
                CREATE INDEX idx_orders_user_id ON orders(user_id);
                CREATE INDEX idx_orders_status ON orders(status);
                CREATE INDEX idx_orders_status_order_date ON orders(status, order_date);
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