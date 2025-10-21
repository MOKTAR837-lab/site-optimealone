from typing import Dict, List
import uuid

class MealPlanner:
    """Générateur de plans alimentaires"""
    
    # Base de repas exemples (à enrichir)
    MEALS_DATABASE = {
        "breakfast": [
            {
                "name": "Omelette aux légumes",
                "calories": 350, "protein": 25, "carbs": 15, "fat": 20,
                "ingredients": ["3 oeufs", "Poivrons", "Tomates", "Oignons"],
                "instructions": "Battre les oeufs, ajouter légumes, cuire à la poêle"
            },
            {
                "name": "Porridge protéiné",
                "calories": 400, "protein": 20, "carbs": 50, "fat": 12,
                "ingredients": ["Flocons avoine 80g", "Lait 200ml", "Whey 30g", "Fruits"],
                "instructions": "Cuire flocons dans lait, ajouter whey et fruits"
            },
            {
                "name": "Pancakes protéinés",
                "calories": 380, "protein": 30, "carbs": 40, "fat": 10,
                "ingredients": ["Oeufs 2", "Banane 1", "Whey 40g", "Flocons 40g"],
                "instructions": "Mixer, cuire en pancakes, servir avec fruits"
            }
        ],
        "lunch": [
            {
                "name": "Poulet riz brocoli",
                "calories": 550, "protein": 50, "carbs": 60, "fat": 12,
                "ingredients": ["Poulet 200g", "Riz basmati 100g", "Brocoli 200g"],
                "instructions": "Griller poulet, cuire riz, vapeur brocoli"
            },
            {
                "name": "Saumon patate douce",
                "calories": 580, "protein": 45, "carbs": 50, "fat": 20,
                "ingredients": ["Saumon 180g", "Patate douce 200g", "Haricots verts"],
                "instructions": "Four saumon 15min, patate vapeur, haricots sautés"
            },
            {
                "name": "Pâtes bolognaise légère",
                "calories": 600, "protein": 40, "carbs": 70, "fat": 15,
                "ingredients": ["Pâtes 100g", "Boeuf haché 5% 150g", "Tomates", "Légumes"],
                "instructions": "Cuire pâtes, mijoter sauce bolognaise maison"
            }
        ],
        "dinner": [
            {
                "name": "Filet de dinde quinoa",
                "calories": 500, "protein": 45, "carbs": 50, "fat": 10,
                "ingredients": ["Dinde 180g", "Quinoa 80g", "Légumes vapeur"],
                "instructions": "Griller dinde, cuire quinoa, légumes vapeur"
            },
            {
                "name": "Poisson blanc légumes",
                "calories": 450, "protein": 40, "carbs": 35, "fat": 15,
                "ingredients": ["Cabillaud 200g", "Courgettes", "Tomates", "Riz"],
                "instructions": "Four poisson papillote, légumes ratatouille"
            },
            {
                "name": "Oeufs légumes rôtis",
                "calories": 420, "protein": 30, "carbs": 30, "fat": 20,
                "ingredients": ["Oeufs 3", "Légumes variés", "Patates"],
                "instructions": "Rôtir légumes au four, ajouter oeufs pochés"
            }
        ],
        "snack": [
            {
                "name": "Yaourt grec fruits secs",
                "calories": 200, "protein": 15, "carbs": 20, "fat": 8,
                "ingredients": ["Yaourt grec 150g", "Amandes 20g", "Miel"],
                "instructions": "Mélanger yaourt avec fruits secs et miel"
            },
            {
                "name": "Shaker protéiné",
                "calories": 150, "protein": 25, "carbs": 10, "fat": 3,
                "ingredients": ["Whey 30g", "Eau/Lait", "Banane"],
                "instructions": "Mixer tous les ingrédients"
            }
        ]
    }
    
    @staticmethod
    def generate_plan(target_calories: float, protein_g: float, carbs_g: float, 
                     fat_g: float, duration_days: int, meals_per_day: int) -> Dict:
        """Génère un plan alimentaire"""
        
        import random
        
        plan_id = str(uuid.uuid4())
        days = []
        
        # Répartition calories par repas
        if meals_per_day == 3:
            meal_distribution = {
                "breakfast": 0.30,
                "lunch": 0.40,
                "dinner": 0.30
            }
        elif meals_per_day == 4:
            meal_distribution = {
                "breakfast": 0.25,
                "lunch": 0.35,
                "snack": 0.10,
                "dinner": 0.30
            }
        else:  # 5-6 repas
            meal_distribution = {
                "breakfast": 0.20,
                "snack1": 0.10,
                "lunch": 0.30,
                "snack2": 0.10,
                "dinner": 0.30
            }
        
        # Génère chaque jour
        for day_num in range(1, duration_days + 1):
            day_meals = []
            day_total_cal = 0
            day_total_prot = 0
            day_total_carbs = 0
            day_total_fat = 0
            
            for meal_type, ratio in meal_distribution.items():
                target_meal_cal = target_calories * ratio
                
                # Choisit repas aléatoire proche des macros
                meal_type_key = meal_type.replace("snack1", "snack").replace("snack2", "snack")
                available_meals = MealPlanner.MEALS_DATABASE.get(meal_type_key, [])
                
                if available_meals:
                    meal = random.choice(available_meals)
                    
                    day_meals.append({
                        "meal_type": meal_type,
                        "meal_name": meal["name"],
                        "calories": meal["calories"],
                        "protein_g": meal["protein"],
                        "carbs_g": meal["carbs"],
                        "fat_g": meal["fat"],
                        "ingredients": meal["ingredients"],
                        "instructions": meal["instructions"]
                    })
                    
                    day_total_cal += meal["calories"]
                    day_total_prot += meal["protein"]
                    day_total_carbs += meal["carbs"]
                    day_total_fat += meal["fat"]
            
            days.append({
                "day": day_num,
                "total_calories": round(day_total_cal, 0),
                "total_protein_g": round(day_total_prot, 1),
                "total_carbs_g": round(day_total_carbs, 1),
                "total_fat_g": round(day_total_fat, 1),
                "meals": day_meals
            })
        
        # Liste de courses
        shopping_list = [
            "Poulet 1.5kg", "Oeufs 12", "Riz basmati 500g",
            "Légumes variés", "Fruits frais", "Yaourt grec",
            "Flocons avoine", "Patates douces", "Poisson blanc"
        ]
        
        return {
            "plan_id": plan_id,
            "duration_days": duration_days,
            "daily_target": {
                "calories": target_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g
            },
            "days": days,
            "shopping_list": shopping_list,
            "notes": [
                "Ajuster portions selon besoins",
                "Boire 2-3L eau/jour",
                "Privilégier cuisson sans matière grasse",
                "Varier les sources de protéines"
            ]
        }
