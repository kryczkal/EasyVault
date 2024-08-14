import os
import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db

# Example call:
# {
#   "order_id": 123
# }

@functions_framework.http
def delete_order(request):
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
        with db.connect() as conn:
            query = f'DELETE FROM orders WHERE id = "{order_id}"'
            conn.execute(query)
            if conn.rowcount == 0:
                return f'Order does not exist with id: {order_id}', 404
            conn.commit()
            return f'Order deleted with id: {order_id}', 200
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500