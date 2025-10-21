from pydantic import BaseModel, Field
from typing import List, Optional

class RecipeSearchRequest(BaseModel):
    """Recherche recettes"""
    target_calories: Optional[float] = None
    protein_g: Optional[float] = None
    meal_type: Optional[str] = None  # breakfast, lunch, dinner
    diet_type: str = "omnivore"
    max_prep_time: Optional[int] = None  # minutes

class Recipe(BaseModel):
    """Une recette"""
    name: str
    meal_type: str
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    prep_time: int  # minutes
    difficulty: str  # easy, medium, hard
    ingredients: List[str]
    instructions: str
    match_score: float = Field(1.0, description="Score matching 0-1")

class RecipeSearchResponse(BaseModel):
    """Résultats recherche recettes"""
    recipes: List[Recipe]
    total_found: int
