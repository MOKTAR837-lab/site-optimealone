from typing import List, Dict

class RecipeMatcher:
    """Matching recettes selon critères"""
    
    RECIPES = [
        {
            "name": "Bowl Buddha protéiné",
            "meal_type": "lunch",
            "calories": 520, "protein": 40, "carbs": 55, "fat": 15,
            "prep_time": 20, "difficulty": "easy",
            "ingredients": ["Quinoa", "Poulet", "Avocat", "Légumes variés"],
            "instructions": "Cuire quinoa et poulet, assembler bowl avec légumes frais"
        },
        {
            "name": "Salade Caesar poulet grillé",
            "meal_type": "lunch",
            "calories": 450, "protein": 45, "carbs": 20, "fat": 22,
            "prep_time": 15, "difficulty": "easy",
            "ingredients": ["Laitue", "Poulet 150g", "Parmesan", "Croûtons"],
            "instructions": "Griller poulet, assembler salade, sauce caesar légère"
        },
        {
            "name": "Wrap thon avocat",
            "meal_type": "lunch",
            "calories": 400, "protein": 35, "carbs": 35, "fat": 15,
            "prep_time": 10, "difficulty": "easy",
            "ingredients": ["Tortilla", "Thon", "Avocat", "Crudités"],
            "instructions": "Émietter thon, écraser avocat, rouler dans tortilla"
        }
    ]
    
    @staticmethod
    def search_recipes(target_calories=None, protein_g=None, meal_type=None, max_prep_time=None):
        """Recherche recettes matchant critères"""
        results = []
        
        for recipe in RecipeMatcher.RECIPES:
            match_score = 1.0
            
            # Filter meal_type
            if meal_type and recipe["meal_type"] != meal_type:
                continue
            
            # Filter prep_time
            if max_prep_time and recipe["prep_time"] > max_prep_time:
                continue
            
            # Score calories
            if target_calories:
                cal_diff = abs(recipe["calories"] - target_calories)
                match_score *= max(0, 1 - (cal_diff / target_calories))
            
            # Score protein
            if protein_g:
                prot_diff = abs(recipe["protein"] - protein_g)
                match_score *= max(0, 1 - (prot_diff / protein_g))
            
            results.append({
                **recipe,
                "match_score": round(match_score, 2)
            })
        
        # Trier par score
        results.sort(key=lambda x: x["match_score"], reverse=True)
        
        return results
