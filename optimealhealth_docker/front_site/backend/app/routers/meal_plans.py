from fastapi import APIRouter
from app.schemas.meal_plan import MealPlanRequest, MealPlanResponse
from app.services.meal_planner import MealPlanner

router = APIRouter(prefix="/api/meal-plans", tags=["Meal Plans - OptimealHealth"])

@router.post("/generate", response_model=MealPlanResponse)
async def generate_meal_plan(request: MealPlanRequest):
    """
    🍽️ Génération Plan Alimentaire Personnalisé
    
    Génère un plan sur X jours avec:
    - Répartition macros
    - Repas équilibrés
    - Liste de courses
    
    OptimealHealth uniquement - Europe
    """
    planner = MealPlanner()
    
    plan = planner.generate_plan(
        target_calories=request.target_calories,
        protein_g=request.protein_g,
        carbs_g=request.carbs_g,
        fat_g=request.fat_g,
        duration_days=request.duration_days,
        meals_per_day=request.meals_per_day
    )
    
    return plan
