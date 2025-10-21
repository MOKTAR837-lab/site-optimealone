from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import pytesseract
from PIL import Image
import io
import re
from typing import List, Dict
import logging

router = APIRouter(prefix="/api/menu", tags=["menu"])
logger = logging.getLogger(__name__)

# Base de données simplifiée Nutri-Score (à enrichir avec CIQUAL)
NUTRISCORE_DB = {
    # Salades
    "salade": {"score": "A", "calories": 150, "category": "Salade"},
    "salade césar": {"score": "B", "calories": 350, "category": "Salade"},
    "salade niçoise": {"score": "B", "calories": 300, "category": "Salade"},
    
    # Burgers
    "burger": {"score": "D", "calories": 700, "category": "Burger"},
    "cheeseburger": {"score": "D", "calories": 750, "category": "Burger"},
    "hamburger": {"score": "D", "calories": 650, "category": "Burger"},
    
    # Pizzas
    "pizza": {"score": "C", "calories": 800, "category": "Pizza"},
    "pizza margherita": {"score": "C", "calories": 700, "category": "Pizza"},
    "pizza reine": {"score": "D", "calories": 850, "category": "Pizza"},
    "pizza 4 fromages": {"score": "D", "calories": 900, "category": "Pizza"},
    
    # Pâtes
    "pâtes": {"score": "B", "calories": 500, "category": "Pâtes"},
    "spaghetti": {"score": "B", "calories": 520, "category": "Pâtes"},
    "carbonara": {"score": "D", "calories": 650, "category": "Pâtes"},
    "bolognaise": {"score": "C", "calories": 580, "category": "Pâtes"},
    
    # Viandes
    "steak": {"score": "B", "calories": 400, "category": "Viande"},
    "poulet": {"score": "A", "calories": 300, "category": "Viande"},
    "saumon": {"score": "A", "calories": 350, "category": "Poisson"},
    
    # Desserts
    "tarte": {"score": "D", "calories": 400, "category": "Dessert"},
    "tiramisu": {"score": "D", "calories": 450, "category": "Dessert"},
    "mousse chocolat": {"score": "D", "calories": 380, "category": "Dessert"},
    "salade fruits": {"score": "A", "calories": 120, "category": "Dessert"},
}

NUTRISCORE_COLORS = {
    "A": "🟢 Excellent",
    "B": "🟡 Bon",
    "C": "🟠 Moyen",
    "D": "🟠 Médiocre",
    "E": "🔴 Mauvais"
}

def extract_text_from_image(image_bytes: bytes) -> str:
    """Extrait le texte d'une image avec Tesseract OCR"""
    try:
        image = Image.open(io.BytesIO(image_bytes))
        
        # OCR avec français et anglais
        text = pytesseract.image_to_string(image, lang='fra+eng')
        
        logger.info(f"Texte extrait: {text[:200]}...")
        return text
    except Exception as e:
        logger.error(f"Erreur OCR: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'extraction du texte: {str(e)}")

def analyze_menu_text(text: str) -> List[Dict]:
    """Analyse le texte du menu et identifie les plats avec Nutri-Score"""
    text_lower = text.lower()
    found_dishes = []
    
    # Recherche des plats dans le texte
    for dish_name, dish_info in NUTRISCORE_DB.items():
        if dish_name in text_lower:
            found_dishes.append({
                "name": dish_name.title(),
                "nutriscore": dish_info["score"],
                "nutriscore_label": NUTRISCORE_COLORS[dish_info["score"]],
                "calories": dish_info["calories"],
                "category": dish_info["category"]
            })
    
    # Si aucun plat trouvé, on fait une analyse plus permissive
    if not found_dishes:
        # Recherche de mots-clés génériques
        lines = text.split('\n')
        for line in lines:
            line_clean = line.strip().lower()
            if len(line_clean) > 3 and len(line_clean) < 50:
                # Recherche partielle
                for dish_name, dish_info in NUTRISCORE_DB.items():
                    if any(word in line_clean for word in dish_name.split()):
                        found_dishes.append({
                            "name": line.strip().title() or dish_name.title(),
                            "nutriscore": dish_info["score"],
                            "nutriscore_label": NUTRISCORE_COLORS[dish_info["score"]],
                            "calories": dish_info["calories"],
                            "category": dish_info["category"]
                        })
                        break
    
    # Tri par Nutri-Score (A meilleur que E)
    found_dishes.sort(key=lambda x: x["nutriscore"])
    
    # Suppression des doublons
    seen = set()
    unique_dishes = []
    for dish in found_dishes:
        if dish["name"] not in seen:
            seen.add(dish["name"])
            unique_dishes.append(dish)
    
    return unique_dishes

@router.post("/analyze")
async def analyze_menu(image: UploadFile = File(...)):
    """
    Analyse une photo de menu et retourne le Nutri-Score de chaque plat
    
    - **image**: Photo du menu (JPEG, PNG)
    
    Returns:
    - Liste des plats détectés avec leur Nutri-Score
    - Suggestion du meilleur choix santé
    """
    # Vérification du type de fichier
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Le fichier doit être une image")
    
    # Lecture de l'image
    image_bytes = await image.read()
    
    if len(image_bytes) > 10 * 1024 * 1024:  # 10 Mo max
        raise HTTPException(status_code=400, detail="Image trop volumineuse (max 10 Mo)")
    
    # Extraction du texte via OCR
    try:
        text = extract_text_from_image(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur OCR: {str(e)}")
    
    if not text.strip():
        return JSONResponse({
            "success": False,
            "message": "Aucun texte détecté dans l'image. Assurez-vous que le texte est lisible.",
            "dishes": [],
            "best_choice": None,
            "extracted_text": ""
        })
    
    # Analyse du menu
    dishes = analyze_menu_text(text)
    
    if not dishes:
        return JSONResponse({
            "success": False,
            "message": "Aucun plat reconnu dans le menu. Notre base contient principalement des plats courants (salades, burgers, pizzas, pâtes).",
            "dishes": [],
            "best_choice": None,
            "extracted_text": text[:500]  # Premiers 500 caractères pour debug
        })
    
    # Meilleur choix (Nutri-Score A ou B)
    best_choice = dishes[0] if dishes[0]["nutriscore"] in ["A", "B"] else None
    
    return JSONResponse({
        "success": True,
        "message": f"{len(dishes)} plat(s) détecté(s) dans le menu",
        "dishes": dishes,
        "best_choice": best_choice,
        "extracted_text": text[:500] if len(text) > 500 else text
    })

@router.get("/health")
async def health_check():
    """Vérifie que Tesseract OCR est installé"""
    try:
        version = pytesseract.get_tesseract_version()
        return {
            "status": "ok",
            "tesseract_version": str(version),
            "languages": ["fra", "eng"]
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }