from pydantic import BaseModel
from typing import List

class FoodItem(BaseModel):
    name: str
    quantity: str
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float

class FoodAnalysisResponse(BaseModel):
    detected_foods: List[FoodItem]
    total_calories: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
