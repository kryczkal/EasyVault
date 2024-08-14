import os
import functions_framework
import sqlalchemy
import requests
from google.cloud import secretmanager

from connect_to_db import connect_to_db
@functions_framework.http
def create_sessions(request):
    try:
        db = connect_to_db()
        with db.connect() as conn:
            result = conn.execute(
                sqlalchemy.text("SELECT id, user_id, start_service, end_service FROM orders WHERE status = 'pending' AND start_service <= NOW()")
            )
            orders = result.fetchall()
            if not orders:
                return 'No orders to create sessions for', 200
            
            session_creation_url = os.environ.get("SESSION_CREATION_URL")
            if not session_creation_url:
                return 'Session creation URL not found', 500

            for order in orders:
                order_id = order[0]
                # Call the session_creation function
                response = requests.post(
                    session_creation_url,
                    json={'order_id': order_id},
                    headers={'Content-Type': 'application/json'}
                )
                if response.status_code != 200:
                    print(f"Failed to create session for order {order_id}: {response.text}")

            conn.commit()
            return f'Sessions created for orders: {", ".join([str(order[0]) for order in orders])}', 200
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500