from fastapi import Request, HTTPException, status
from app.config import settings
import logging

logger = logging.getLogger(__name__)

def verify_api_key(api_key: str) -> bool:
    """Verify the provided API key"""
    return api_key == settings.API_KEY

async def api_key_middleware(request: Request, call_next):
    """Middleware to check API key for all /api routes"""
    # Skip API key check for health checks or non-API routes
    if not request.url.path.startswith("/api/"):
        response = await call_next(request)
        return response
    
    # Extract API key from headers
    api_key = request.headers.get("X-API-Key")
    
    if not api_key:
        logger.warning(f"API access attempt without API key from {request.client.host}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required. Include X-API-Key header in your request."
        )
    
    if not verify_api_key(api_key):
        logger.warning(f"Invalid API key attempt from {request.client.host}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid API key"
        )
    
    # Log successful API access
    logger.info(f"API access granted from {request.client.host} for {request.url.path}")
    
    response = await call_next(request)
    return response