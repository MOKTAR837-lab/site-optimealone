from fastapi import APIRouter
from app.schemas.recipe import RecipeSearchRequest, RecipeSearchResponse, Recipe
from app.services.recipe_matcher import RecipeMatcher

router = APIRouter(prefix="/api/recipes", tags=["Recipes - OptimealHealth"])

@router.post("/search", response_model=RecipeSearchResponse)
async def search_recipes(request: RecipeSearchRequest):
    """
    🥗 Suggestions Recettes Personnalisées
    
    Trouve recettes selon:
    - Macros cibles
    - Type de repas
    - Temps préparation
    
    OptimealHealth uniquement - Europe
    """
    matcher = RecipeMatcher()
    
    recipes = matcher.search_recipes(
        target_calories=request.target_calories,
        protein_g=request.protein_g,
        meal_type=request.meal_type,
        max_prep_time=request.max_prep_time
    )
    
    return {
        "recipes": recipes,
        "total_found": len(recipes)
    }
