import requests
from datetime import datetime, timedelta
from app.database import get_db_collection
from app.config import settings

# Static configuration for cities
CITIES = [
    {"name": "Tokyo", "lat": 35.6895, "lng": 139.6917, "timezone": "Asia/Tokyo"},
    {"name": "San Diego", "lat": 32.7628, "lng": -117.1633, "timezone": "America/Los_Angeles"},
    {"name": "Las Vegas", "lat": 36.1699, "lng": -115.1398, "timezone": "America/Los_Angeles"},
    {"name": "London", "lat": 51.5074, "lng": -0.1278, "timezone": "Europe/London"},
    {"name": "Sydney", "lat": -33.8688, "lng": 151.2093, "timezone": "Australia/Sydney"},
    {"name": "New York", "lat": 40.7128, "lng": -74.0060, "timezone": "America/New_York"}
]

def fetch_external_weather(lat, lng):
    """Fetch raw data from Open-Meteo"""
    try:
        url = f"{settings.OPEN_METEO_URL}?latitude={lat}&longitude={lng}&current_weather=true"
        response = requests.get(url)
        response.raise_for_status()
        return response.json().get("current_weather", {})
    except Exception as e:
        print(f"External API Error: {e}")
        return None

def get_city_readings():
    """Main service logic to get weather data with caching"""
    collection = get_db_collection("city_readings")
    results = []

    for index, city in enumerate(CITIES):
        # 1. Check DB for recent data
        cached_doc = collection.find_one({"city": city["name"]})
        
        needs_update = True
        if cached_doc:
            last_updated = cached_doc.get("updated_at")
            if last_updated and (datetime.utcnow() - last_updated) < timedelta(minutes=settings.REFRESH_INTERVAL_MINUTES):
                needs_update = False
                results.append(cached_doc["data"])

        # 2. If missing or stale, fetch new data
        if needs_update:
            weather_data = fetch_external_weather(city["lat"], city["lng"])
            
            if weather_data:
                temp_c = weather_data.get("temperature")
                # Calculate F
                temp_f = round((temp_c * 9/5) + 32, 2) if temp_c is not None else None
                
                reading = {
                    "id": index + 1,
                    "city": city["name"],
                    "tempC": temp_c,
                    "tempF": temp_f,
                    "timezone": city["timezone"],
                    "localTime": datetime.now().isoformat()
                }
                
                # Upsert into MongoDB
                collection.update_one(
                    {"city": city["name"]},
                    {
                        "$set": {
                            "updated_at": datetime.utcnow(),
                            "data": reading
                        }
                    },
                    upsert=True
                )
                results.append(reading)
            elif cached_doc:
                # Fallback to old data if API fails
                results.append(cached_doc["data"])
    
    return results
