import functions_framework
import sqlalchemy

from connect_to_db import connect_to_db

@functions_framework.http
def delete_user(request):
    try:
        # Parse request JSON
        request_json = request.get_json(silent=True)
        if not request_json:
            return 'No JSON data in request', 400
        
        google_id = request_json.get('google_id')
        user_id = request_json.get('user_id')
        
        if not any([google_id, user_id]):
            return 'Missing required fields: google_id or user_id', 400

    except Exception as e:
        return f'Error parsing request: {str(e)}', 400

    try:
        db = connect_to_db()
        with db.connect() as conn:
            # Check if user exists by google_id or user_id
            if google_id:
                result = conn.execute(sqlalchemy.text("SELECT id FROM users WHERE google_id = :google_id"), {"google_id": google_id})
            else:
                result = conn.execute(sqlalchemy.text("SELECT id FROM users WHERE id = :user_id"), {"user_id": user_id})
            
            existing_user = result.fetchone()
            if not existing_user:
                return f'User does not exist with id: {google_id if google_id else user_id}', 404

            # Delete the user
            if google_id:
                conn.execute(sqlalchemy.text("DELETE FROM users WHERE google_id = :google_id"), {"google_id": google_id})
            else:
                conn.execute(sqlalchemy.text("DELETE FROM users WHERE id = :user_id"), {"user_id": user_id})

            conn.commit()
            return f'User deleted with id: {google_id if google_id else user_id}', 200

    except sqlalchemy.exc.IntegrityError as e:
        return f'Database integrity error: {str(e)}', 400
    except sqlalchemy.exc.OperationalError as e:
        return f'Database connection error: {str(e)}', 500
    except Exception as e:
        return f'Unexpected error: {str(e)}', 500
