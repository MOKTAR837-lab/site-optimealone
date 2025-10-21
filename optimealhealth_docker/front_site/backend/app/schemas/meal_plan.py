from pydantic import BaseModel, Field
from typing import List, Dict, Optional

class MealPlanRequest(BaseModel):
    """Demande génération plan alimentaire"""
    questionnaire_amc_id: Optional[str] = None
    target_calories: float = Field(..., description="Calories cibles/jour")
    protein_g: float
    carbs_g: float
    fat_g: float
    duration_days: int = Field(7, ge=1, le=30, description="Durée du plan")
    meals_per_day: int = Field(3, ge=2, le=6)
    diet_type: str = Field("omnivore", description="Type alimentation")
    restrictions: List[str] = Field(default=[], description="Restrictions alimentaires")

class Meal(BaseModel):
    """Un repas"""
    meal_type: str  # breakfast, lunch, dinner, snack
    meal_name: str
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    ingredients: List[str]
    instructions: str

class DayPlan(BaseModel):
    """Plan d'une journée"""
    day: int
    total_calories: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    meals: List[Meal]

class MealPlanResponse(BaseModel):
    """Plan alimentaire complet"""
    plan_id: str
    duration_days: int
    daily_target: Dict[str, float]
    days: List[DayPlan]
    shopping_list: List[str]
    notes: List[str]
