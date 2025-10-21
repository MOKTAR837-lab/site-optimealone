class NutritionCalculator:
    """Calculs nutritionnels"""
    
    @staticmethod
    def calculate_bmr(weight_kg: float, height_cm: float, age: int, gender: str) -> float:
        """BMR - Métabolisme de base (Mifflin-St Jeor)"""
        if gender.upper() == "M":
            return (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
        return (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
    
    @staticmethod
    def calculate_tdee(bmr: float, activity: str) -> float:
        """TDEE - Dépense totale"""
        multipliers = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }
        return bmr * multipliers.get(activity, 1.2)
    
    @staticmethod
    def calculate_macros(calories: float, goal: str) -> dict:
        """Calcul macronutriments"""
        if goal == "lose_weight":
            p, c, f = 0.30, 0.45, 0.25
        elif goal == "gain_muscle":
            p, c, f = 0.35, 0.45, 0.20
        else:
            p, c, f = 0.25, 0.45, 0.30
        
        return {
            "protein_g": round((calories * p) / 4, 1),
            "carbs_g": round((calories * c) / 4, 1),
            "fat_g": round((calories * f) / 9, 1)
        }
