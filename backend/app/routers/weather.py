from fastapi import APIRouter
from typing import List
from app.models import CityReading
from app.services.weather_service import get_city_readings

router = APIRouter()

@router.get("/weather", response_model=List[CityReading])
def get_weather():
    return get_city_readings()
