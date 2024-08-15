import functions_framework
import sqlalchemy
from flask import jsonify

from connect_to_db import connect_to_db

@functions_framework.http
def db_state(request):
    try:
        db = connect_to_db()
        print("Connection established")
        with db.connect() as conn:
            # Query all users
            users_result = conn.execute(sqlalchemy.text("SELECT * FROM users"))
            users = [dict(row._mapping) for row in users_result.fetchall()]
            print(f"Number of users: {len(users)}")

            # Query all orders
            orders_result = conn.execute(sqlalchemy.text("SELECT * FROM orders"))
            orders = [dict(row._mapping) for row in orders_result.fetchall()]
            print(f"Number of orders: {len(orders)}")


        # Construct the response dictionary
        database_state = {
            "users": users,
            "orders": orders
        }

        return jsonify(database_state), 200

    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500
