import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db
from delete_bucket import delete_bucket

#
@functions_framework.http
def session_deletion(request):
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
        # find the bucket_id from the order_id
        with db.connect() as conn:
            query = f"SELECT bucket_id FROM orders WHERE id = '{order_id}'"
            result = conn.execute(sqlalchemy.text(query))
            bucket_id = result.fetchone()[0]
        
        if not bucket_id:
            raise ValueError(f'No bucket found for order ID: {order_id}')
        
        # Delete the bucket
        delete_bucket(bucket_id)

        # Delete the order
        # with db.connect() as conn:
        #     query = f'DELETE FROM orders WHERE id = "{order_id}"'
        #     conn.execute(query)
            
        return f'Bucket deleted with ID: {bucket_id} for order {order_id}', 200
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500