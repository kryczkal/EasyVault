import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db
from create_bucket import create_bucket
from hash_gen import hash_gen

@functions_framework.http
def session_creation(request):
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            return 'No JSON data in request', 400
        
        order_id = request_json.get('order_id')
        
        if not all([order_id]):
            return 'Missing required fields: order_id', 400

    except Exception as e:
        return f'Error parsing request: {str(e)}', 400

    try:
        db = connect_to_db()
        # Generate unique bucket_id
        bucket_id = hash_gen()
        with db.connect() as conn:
            query = f'SELECT * FROM orders WHERE bucket_id = "{bucket_id}"'
            result = conn.execute(query)
            while result.fetchone():
                bucket_id = hash_gen()

        # Create bucket
        create_bucket(bucket_id)

        # Insert bucket_id into order with order_id
        with db.connect() as conn:
            query = f'INSERT INTO orders (bucket_id) VALUES ("{bucket_id}")'
            conn.execute(query)
            
        return f'Bucket created with ID: {bucket_id} for order {order_id}', 200
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500