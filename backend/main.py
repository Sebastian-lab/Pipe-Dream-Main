from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import weather
from app.config import settings

app = FastAPI(title="Weather API")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Routers
app.include_router(weather.router, prefix="/api", tags=["Weather"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=settings.DEBUG)
