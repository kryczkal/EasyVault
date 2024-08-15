import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db
from create_bucket import create_bucket
from hash_gen import hash_gen
from email_user import email_user

@functions_framework.http
def session_creation(request):
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            return 'No JSON data in request', 400
        
        order_id = request_json.get('order_id')
        if not order_id:
            return 'Missing required fields: order_id', 400

    except Exception as e:
        return f'Error parsing request: {str(e)}', 400

    try:
        db = connect_to_db()
        print("Connection established")

        # Generate a unique bucket_id
        bucket_id = hash_gen()
        with db.connect() as conn:
            while True:
                query = "SELECT 1 FROM orders WHERE bucket_id = :bucket_id"
                result = conn.execute(sqlalchemy.text(query), {"bucket_id": bucket_id})
                if not result.fetchone():
                    break
                bucket_id = hash_gen()
            print(f"Found unique bucket ID: {bucket_id}")

            # Create bucket
            create_bucket(bucket_id)
            print(f"Bucket {bucket_id} created")

            # Update bucket_id and status in the orders table
            update_query = """
            UPDATE orders 
            SET bucket_id = :bucket_id, status = 'active'
            WHERE id = :order_id
            """
            conn.execute(sqlalchemy.text(update_query), {"bucket_id": bucket_id, "order_id": order_id})
            print(f"Order {order_id} updated")

            conn.commit()

            # Retrieve the user's email associated with the order
            email_query = """
            SELECT u.email 
            FROM orders o 
            JOIN users u ON o.user_id = u.id 
            WHERE o.id = :order_id
            """
            result = conn.execute(sqlalchemy.text(email_query), {"order_id": order_id})
            email_row = result.fetchone()
            
            if not email_row:
                raise ValueError(f'No email found for order ID: {order_id}')
            
            email = email_row[0]
            print(f"Email retrieved for order {order_id}")


        # Send email to the user
        email_user(email, bucket_id)
        print(f"Email sent to {email}")

        return f'Bucket created with ID: {bucket_id} for order {order_id} and email sent to {email}', 200

    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500
