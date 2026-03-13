from fastapi import APIRouter, HTTPException, status
from typing import List, Dict, Any
from app.database import get_db_collection
import logging

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/predictions")
def get_predictions() -> List[Dict[str, Any]]:
    """
    Get all prediction documents from the predicted collection.
    Returns predictions with timestamps, values, model file, and creation date.
    """
    try:
        logger.info("Predictions data requested")
        collection = get_db_collection("predicted")
        
        predictions = list(collection.find(
            {},
            {
                "_id": 1,
                "city": 1,
                "predictions": 1,
                "timestamps": 1,
                "model_file": 1,
                "created_at": 1
            }
        ).sort("created_at", -1))
        
        if not predictions:
            logger.warning("No predictions available")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No predictions available at this time"
            )
        
        for pred in predictions:
            pred["_id"] = str(pred["_id"])
            if pred.get("created_at"):
                pred["created_at"] = str(pred["created_at"])
        
        logger.info(f"Successfully returned {len(predictions)} prediction documents")
        return predictions
        
    except HTTPException:
        raise
        
    except Exception as e:
        logger.error(f"Error fetching predictions: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch predictions. Please try again later."
        )
