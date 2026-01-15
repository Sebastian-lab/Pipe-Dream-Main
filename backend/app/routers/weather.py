from fastapi import APIRouter
from typing import List
from app.models import CityReading
from app.services.weather_service import get_city_readings, get_city_history

router = APIRouter()

@router.get("/weather", response_model=List[CityReading])
def get_weather():
    cities = get_city_readings()
    return cities

@router.get("/weather/history")
def get_weather_history():
    return get_city_history()
