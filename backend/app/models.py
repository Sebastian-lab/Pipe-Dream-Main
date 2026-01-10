from pydantic import BaseModel
from typing import Optional

# This matches your TypeScript interface CityReading
class CityReading(BaseModel):
    id: int
    city: str
    tempF: Optional[float] = None
    tempC: Optional[float] = None
    timezone: Optional[str] = None
    localTime: str
