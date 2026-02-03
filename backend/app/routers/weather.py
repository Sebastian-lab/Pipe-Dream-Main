from fastapi import APIRouter, HTTPException, status
from typing import List
from app.models import CityReading
from app.services.weather_service import get_city_readings, get_city_history
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/weather", response_model=List[CityReading])
def get_weather():
    """
    Get current weather readings for all cities.
    Returns the last 10 readings for each city.
    """
    try:
        logger.info("Weather data requested")
        cities = get_city_readings()
        
        if not cities:
            logger.warning("No weather data available")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No weather data available at this time"
            )
        
        logger.info(f"Successfully returned weather data for {len(cities)} cities")
        return cities
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
        
    except Exception as e:
        logger.error(f"Error fetching weather data: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch weather data. Please try again later."
        )

@router.get("/weather/history")
def get_weather_history():
    """
    Get weather data history for analysis purposes.
    This endpoint returns raw historical data.
    """
    try:
        logger.info("Weather history requested")
        history_data = get_city_history()
        
        if history_data is None:
            logger.warning("No historical data available")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No historical data available"
            )
        
        logger.info("Successfully returned weather history")
        return history_data
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
        
    except Exception as e:
        logger.error(f"Error fetching weather history: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch weather history. Please try again later."
        )
