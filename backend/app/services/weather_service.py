import requests
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, Any
from app.database import get_db_collection
from app.config import settings
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

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
    """Get weather readings, keep last 10 per city"""
    collection = get_db_collection("city_readings")
    cities = []

    for city in CITIES:
        cached_doc = collection.find_one({"city": city["name"]})
        readings = cached_doc.get("readings", []) if cached_doc else []
        last_updated = cached_doc.get("updated_at") if cached_doc else None

        # Only fetch new data if stale
        needs_update = True
        if last_updated and (datetime.utcnow() - last_updated) < timedelta(minutes=settings.REFRESH_INTERVAL_MINUTES):
            needs_update = False

        if needs_update:
            weather_data = fetch_external_weather(city["lat"], city["lng"])
            if weather_data:
                temp_c = weather_data.get("temperature")
                temp_f = round((temp_c * 9/5) + 32, 2) if temp_c is not None else None

                new_reading = {
                    "tempC": temp_c,
                    "tempF": temp_f,
                    "timezone": city["timezone"],
                    "localTime": datetime.now().isoformat()
                }

                # Push new reading, keep last 10
                collection.update_one(
                    {"city": city["name"]},
                    {
                        "$set": {"updated_at": datetime.utcnow()},
                        "$push": {"readings": {"$each": [new_reading], "$slice": -10}}
                    },
                    upsert=True
                )

                readings.append(new_reading)  # also add to local copy for returning

        # Return full city object with readings
        cities.append({
            "city": city["name"],
            "readings": readings[-10:]  # ensure only last 10
        })
    
    get_city_history()
    return cities

def get_city_history():
    collection = get_db_collection("city_readings")
    data = []
    for city in CITIES:
        cached_doc = collection.find_one({"city": city["name"]})
        if cached_doc and "readings" in cached_doc and cached_doc["readings"]:
            # Convert MongoDB document to regular dict for pandas with proper typing
            doc_dict: Dict[str, Any] = dict(cached_doc)
            # Explicit type cast for pandas - we know this is a dict at this point
            df = pd.json_normalize(doc_dict, record_path="readings", meta=["city"])  # type: ignore
            df["localTime"] = pd.to_datetime(df["localTime"], utc=True).dt.strftime("%H:%M:%S")
            if "timezone" in df.columns:
                df.drop(columns=["timezone"], inplace=True)
            data.append(df)
    
    # Print data for debugging (can be removed in production)
    for x in data:
        print(x) #19:58:20
    return 0