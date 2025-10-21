from fastapi import APIRouter
from app.schemas.questionnaire import QuestionnaireAMC, QuestionnaireHabits
from app.services.nutrition_calculator import NutritionCalculator
from app.services.habits_analyzer import HabitsAnalyzer

router = APIRouter(prefix="/api/questionnaire", tags=["Questionnaire"])

@router.post("/amc")
async def analyze_amc(data: QuestionnaireAMC):
    calc = NutritionCalculator()
    bmr = calc.calculate_bmr(data.weight_kg, data.height_cm, data.age, data.gender.value)
    tdee = calc.calculate_tdee(bmr, data.activity_level.value)
    target_cals = tdee * 0.8 if data.goal.value == "lose_weight" else tdee
    macros = calc.calculate_macros(target_cals, data.goal.value)
    
    return {
        "bmr": round(bmr, 1),
        "tdee": round(tdee, 1),
        "target_calories": round(target_cals, 0),
        **macros
    }

@router.post("/habits")
async def analyze_habits(data: QuestionnaireHabits):
    analyzer = HabitsAnalyzer()
    return analyzer.analyze_habits(data.dict())
