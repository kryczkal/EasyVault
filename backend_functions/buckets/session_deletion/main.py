import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db
from delete_bucket import delete_bucket

@functions_framework.http
def session_deletion(request):
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
        with db.connect() as conn:
            # Find the bucket_id from the order_id
            query = "SELECT bucket_id FROM orders WHERE id = :order_id"
            result = conn.execute(sqlalchemy.text(query), {"order_id": order_id})
            bucket_row = result.fetchone()
            
            if not bucket_row or not bucket_row[0]:
                return f'No bucket found for order ID: {order_id}', 404
            
            bucket_id = bucket_row[0]
            print(f"Bucket ID: {bucket_id}")
            
            # Delete the bucket
            delete_bucket(bucket_id)
            print(f"Bucket {bucket_id} deleted")

            # Update bucket_id and status in orders table
            update_query = """
            UPDATE orders 
            SET bucket_id = NULL, status = 'completed' 
            WHERE id = :order_id
            """
            conn.execute(sqlalchemy.text(update_query), {"order_id": order_id})
            print(f"Order {order_id} updated")

            conn.commit()
        
        return f'Bucket deleted with ID: {bucket_id} for order {order_id}', 200
        
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500
