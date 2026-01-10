from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    MONGO_URI: str
    DB_NAME: str = "weather_db"
    
    # App
    APP_ENV: str = "development"
    DEBUG: bool = False
    
    # External API
    OPEN_METEO_URL: str
    REFRESH_INTERVAL_MINUTES: int = 1

    class Config:
        env_file = ".env"

settings = Settings()
