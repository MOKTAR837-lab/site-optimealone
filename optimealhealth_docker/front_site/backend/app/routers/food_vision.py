from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.food_vision import FoodVisionService
from app.schemas.food_vision import FoodAnalysisResponse

router = APIRouter(prefix="/food-vision", tags=["Food Vision"])

@router.post("/analyze")
async def analyze_food(image: UploadFile = File(...)):
    if not image.content_type.startswith("image/"):
        raise HTTPException(400, "Image requise")
    data = await image.read()
    service = FoodVisionService()
    return await service.analyze_image(data)
