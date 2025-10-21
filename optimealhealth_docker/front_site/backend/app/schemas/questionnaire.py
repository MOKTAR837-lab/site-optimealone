from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum

class Gender(str, Enum):
    MALE = "M"
    FEMALE = "F"

class ActivityLevel(str, Enum):
    SEDENTARY = "sedentary"
    LIGHT = "light"
    MODERATE = "moderate"
    ACTIVE = "active"
    VERY_ACTIVE = "very_active"

class Goal(str, Enum):
    LOSE_WEIGHT = "lose_weight"
    GAIN_MUSCLE = "gain_muscle"
    MAINTAIN = "maintain"
    HEALTH = "health"

class QuestionnaireAMC(BaseModel):
    age: int = Field(..., ge=18, le=100)
    gender: Gender
    weight_kg: float = Field(..., gt=30, lt=300)
    height_cm: float = Field(..., gt=100, lt=250)
    activity_level: ActivityLevel
    goal: Goal

class QuestionnaireHabits(BaseModel):
    diet_type: str
    restrictions: List[str] = []
    allergies: List[str] = []
    meals_per_day: int = Field(..., ge=1, le=6)
    cooking_skills: str
    budget_per_day: Optional[float] = None
    water_intake_liters: float = Field(2.0, ge=0, le=5)
