import os
import functions_framework
import sqlalchemy
from flask import jsonify

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
            return jsonify({'error': 'No JSON data in request'}), 400
        
        order_id = request_json.get('order_id')
        
        if not order_id:
            return jsonify({'error': 'Missing required field: order_id'}), 400

    except Exception as e:
        return jsonify({'error': f'Error parsing request: {str(e)}'}), 400

    try:
        db = connect_to_db()
        with db.connect() as conn:
            print("Connection established")
            query = sqlalchemy.text('DELETE FROM orders WHERE id = :order_id')
            result = conn.execute(query, {'order_id': order_id})
            if result.rowcount == 0:
                return jsonify({'error': f'Order does not exist with id: {order_id}'}), 404
            conn.commit()
            return jsonify({'message': f'Order deleted with id: {order_id}'}), 200

    except sqlalchemy.exc.OperationalError as e:
        return jsonify({'error': f'Database connection error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'error': f'Unexpected error: {str(e)}'}), 500
