import os
import functions_framework
import sqlalchemy
import requests
from google.cloud import secretmanager

from connect_to_db import connect_to_db
from invoke_cloud_function import invoke_cloud_function

@functions_framework.http
def auto_sessions(request):
    try:
        db = connect_to_db()
        with db.connect() as conn:
            result = conn.execute(
                sqlalchemy.text("SELECT id, user_id, start_service, end_service FROM orders WHERE status = 'pending' AND start_service <= NOW()")
            )
            orders = result.fetchall()
            if not orders:
                return 'No orders to create sessions for', 200

            print(f"Creating sessions for orders: {', '.join([str(order[0]) for order in orders])}")
            
            session_creation_name = os.environ.get("GCF_SESSION_CREATION_NAME")
            if not session_creation_name:
                return 'Session creation URL not found', 500

            for order in orders:
                order_id = order[0]

                print("Invoking session creation function")
                response = invoke_cloud_function(session_creation_name, {"order_id": order_id}, {"Content-Type": "application/json"})

                if response.status_code != 200:
                    raise ValueError(f'Error creating session for order ID: {order_id} - {response.status_code} - {response.text}')

            return f'Sessions created for orders: {", ".join([str(order[0]) for order in orders])}', 200
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500