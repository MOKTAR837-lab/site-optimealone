# app/services/validators.py
from typing import List, Tuple
from app.schemas.consultation import WarningItem

def nutrition_guardrails(text: str, profil) -> List[WarningItem]:
    warnings = []
    # Exemples simples (à enrichir)
    if "arachide" in text.lower() and "arachide" in [a.lower() for a in profil.allergies]:
        warnings.append(WarningItem(code="ALLERGEN_ARACHIDE",
                                    message="Présence d'arachide malgré allergie déclarée."))
    # TODO: extraire kcal/protéines etc. et vérifier les bornes
    return warnings