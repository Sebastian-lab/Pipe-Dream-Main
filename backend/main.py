from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.routers import weather
from app.config import settings
from middleware.auth import api_key_middleware
import logging

print("main.py is imported")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Weather API",
    description="Secure Weather Data API",
    version="1.0.0",
    docs_url="/docs" if settings.DEBUG else None,  # Hide docs in production
    redoc_url="/redoc" if settings.DEBUG else None
)

# Add security headers middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response

# Add API key authentication middleware
app.middleware("http")(api_key_middleware)

# Enable CORS with environment-specific origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET"],  # Restrict to GET requests only
    allow_headers=["X-API-Key", "Content-Type"],  # Allow only necessary headers
)

# Register Routers
app.include_router(weather.router, prefix="/api", tags=["Weather"])

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {type(exc).__name__}: {exc}")
    
    if settings.DEBUG:
        # In development, show full error details
        return JSONResponse(
            status_code=500,
            content={
                "detail": f"Internal server error: {type(exc).__name__}: {str(exc)}",
                "type": type(exc).__name__
            }
        )
    else:
        # In production, hide error details
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )

# Health check endpoint (doesn't require API key)
@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "environment": settings.APP_ENV
    }

if __name__ == "__main__":
    import uvicorn
    logger.info(f"Starting Weather API in {settings.APP_ENV} mode")
    logger.info(f"CORS origins: {settings.CORS_ORIGINS}")
    logger.info(f"Debug mode: {settings.DEBUG}")

    print("main.py executed")
    
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=settings.DEBUG,
        log_level="info" if not settings.DEBUG else "debug"
    )
