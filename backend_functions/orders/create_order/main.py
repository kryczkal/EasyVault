import os
import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db

# Example call:
# {
#   "user_id": 123,
#   "start_service": "2024-08-14 15:30:00",
#   "end_service": "2024-08-14 17:30:00",
#   "total_amount": 100.50
# }

@functions_framework.http
def create_order(request):
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            return 'No JSON data in request', 400
        
        user_id = request_json.get('user_id')
        start_service = request_json.get('start_service')
        end_service = request_json.get('end_service')
        total_amount = request_json.get('total_amount')
        
        if not all([user_id, start_service, end_service, total_amount]):
            return 'Missing required fields: user_id, start_service, end_service, or total_amount', 400

    except Exception as e:
        return f'Error parsing request: {str(e)}', 400

    try:
        db = connect_to_db()
        with db.connect() as conn:
            result = conn.execute(
                sqlalchemy.text("INSERT INTO orders (user_id, start_service, end_service, total_amount) VALUES (:user_id, :start_service, :end_service, :total_amount) RETURNING id"),
                {"user_id": user_id, "start_service": start_service, "end_service": end_service, "total_amount": total_amount}
            )

            new_order_id = result.fetchone()[0]
            conn.commit()
            return f'Order created with id: {new_order_id}', 201
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500