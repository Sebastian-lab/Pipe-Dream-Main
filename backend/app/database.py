from pymongo import MongoClient
import certifi
from app.config import settings

def get_db_collection(collection_name: str):
    """
    Creates a MongoDB client and returns the requested collection.
    Uses certifi to handle SSL certificate verification.
    """
    client = MongoClient(settings.MONGO_URI, tlsCAFile=certifi.where())
    db = client[settings.DB_NAME]
    return db[collection_name]
