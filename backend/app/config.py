from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from typing import List, Union

class Settings(BaseSettings):
    # Database
    MONGO_URI: str
    DB_NAME: str = "weather_db"
    
    # App
    APP_ENV: str = "development"
    DEBUG: bool = False
    
    # API Security
    API_KEY: str
    
    # CORS
    CORS_ORIGINS: Union[List[str], str] = ["http://localhost:5173", "http://127.0.0.1:5173"]
    
    # External API
    OPEN_METEO_URL: str
    REFRESH_INTERVAL_MINUTES: int = 1

    model_config = SettingsConfigDict(
        env_file=[".env", ".env.local"],
        case_sensitive=False
    )
    
    @field_validator('CORS_ORIGINS', mode='before')
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str) and not v.startswith('['):
            return [i.strip() for i in v.split(',')]
        return v

settings = Settings()
