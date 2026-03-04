from fastapi import Request
from fastapi.responses import JSONResponse
from app.config import settings
import logging

logger = logging.getLogger(__name__)

def verify_api_key(api_key: str) -> bool:
    return api_key == settings.API_KEY

async def api_key_middleware(request: Request, call_next):
    if not request.url.path.startswith("/api/"):
        return await call_next(request)
    
    api_key = request.headers.get("X-API-Key")
    
    if not api_key:
        logger.warning(f"API access attempt without API key from {request.client.host}")
        return JSONResponse(
            status_code=401,
            content={"detail": "API key required. Include X-API-Key header in your request."}
        )
    
    if not verify_api_key(api_key):
        logger.warning(f"Invalid API key attempt from {request.client.host}")
        return JSONResponse(
            status_code=403,
            content={"detail": "Invalid API key"}
        )
    
    logger.info(f"API access granted from {request.client.host} for {request.url.path}")
    
    response = await call_next(request)
    return response
