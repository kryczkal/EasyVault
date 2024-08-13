import os
import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db

@functions_framework.http
def create_user(request):
    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            return 'No JSON data in request', 400
        
        google_id = request_json.get('google_id')
        email = request_json.get('email')
        name = request_json.get('name')
        
        if not all([google_id, email, name]):
            return 'Missing required fields: google_id, email, or name', 400

    except Exception as e:
        return f'Error parsing request: {str(e)}', 400

    try:
        db = connect_to_db()
        with db.connect() as conn:
            # Check if user already exists
            result = conn.execute(sqlalchemy.text("SELECT id FROM users WHERE google_id = :google_id"), {"google_id": google_id})
            existing_user = result.fetchone()

            if existing_user:
                return f'User already exists with id: {existing_user[0]}', 200

            # Create new user
            result = conn.execute(
                sqlalchemy.text("INSERT INTO users (google_id, email, name) VALUES (:google_id, :email, :name) RETURNING id"),
                {"google_id": google_id, "email": email, "name": name}
            )
            new_user_id = result.fetchone()[0]
            conn.commit()

            return f'User created with id: {new_user_id}', 201
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500