import hashlib
import uuid

def hash_gen():
    unique_id = str(uuid.uuid4())
    
    # Create SHA-1 hash
    hash_object = hashlib.sha1(unique_id.encode())
    hash_hex = hash_object.hexdigest()
    
    return hash_hex