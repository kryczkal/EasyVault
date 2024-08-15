import os
import functions_framework
import sqlalchemy
from google.cloud import secretmanager

from connect_to_db import connect_to_db
from invoke_cloud_function import invoke_cloud_function

@functions_framework.http
def auto_sessions(request):
    try:
        # Retrieve environment variables
        session_creation_name = os.environ.get("GCF_SESSION_CREATION_NAME")
        session_deletion_name = os.environ.get("GCF_SESSION_DELETION_NAME")

        if not session_creation_name:
            return 'Session creation URL not found', 500
        if not session_deletion_name:
            return 'Session deletion URL not found', 500

        db = connect_to_db()
        with db.connect() as conn:
            # Activate sessions for pending orders that should start
            activation_query = """
            SELECT id, user_id, start_service, end_service 
            FROM orders 
            WHERE status = 'pending' AND start_service <= NOW()
            """
            result = conn.execute(sqlalchemy.text(activation_query))
            pending_orders = result.fetchall()
            
            if pending_orders:
                print(f"Creating sessions for orders: {', '.join([str(order[0]) for order in pending_orders])}")
                
                for order in pending_orders:
                    order_id = order[0]
                    print(f"Invoking session creation function for order ID: {order_id}")
                    response = invoke_cloud_function(
                        session_creation_name, 
                        {"order_id": order_id}, 
                        {"Content-Type": "application/json"}
                    )

                    if response.status_code != 200:
                        raise ValueError(f'Error creating session for order ID: {order_id} - {response.status_code} - {response.text}')

            # Deactivate sessions for active orders that have ended
            deactivation_query = """
            SELECT id 
            FROM orders 
            WHERE status = 'active' AND end_service <= NOW()
            """
            result = conn.execute(sqlalchemy.text(deactivation_query))
            active_orders = result.fetchall()
            
            if active_orders:
                print(f"Deleting sessions for orders: {', '.join([str(order[0]) for order in active_orders])}")
                
                for order in active_orders:
                    order_id = order[0]
                    print(f"Invoking session deletion function for order ID: {order_id}")
                    response = invoke_cloud_function(
                        session_deletion_name, 
                        {"order_id": order_id}, 
                        {"Content-Type": "application/json"}
                    )

                    if response.status_code != 200:
                        raise ValueError(f'Error deleting session for order ID: {order_id} - {response.status_code} - {response.text}')

        return 'Auto sessions completed successfully', 200

    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500
