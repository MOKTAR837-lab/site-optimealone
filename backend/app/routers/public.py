# backend/app/routers/public.py
from fastapi import APIRouter, Form, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
import json, re

from app.db.session import get_db
from app.schemas.consultation import ConsultationIn, PatientProfile, ConsultationOut
from app.services.rag import semantic_search
from app.services.prompting import build_prompt
from app.services.chat import generate_brouillon
from app.services.validators import nutrition_guardrails

router = APIRouter(prefix="/api/public", tags=["public"])

def _to_float_fr(val: str) -> float:
    # remplace virgules et espaces insécables, supprime espaces
    v = re.sub(r"\s+", "", val.replace("\u00A0", ""))
    v = v.replace(",", ".")
    return float(v)

@router.post("/consultation", response_model=ConsultationOut)
async def public_consultation(
    age: int = Form(...),
    sexe: str = Form(...),
    taille_cm: str = Form(...),  # strings -> conversion FR
    poids_kg: str = Form(...),
    activite: str = Form("modérée"),
    question: str = Form(...),
    allergies: str = Form("[]"),
    db: AsyncSession = Depends(get_db),
):
    # conversions FR -> float
    try:
        taille_cm_f = _to_float_fr(taille_cm)
        poids_kg_f = _to_float_fr(poids_kg)
    except Exception:
        raise HTTPException(400, detail="Taille/poids : format invalide (utilisez 170 ou 170.5)")

    # bornes simples
    if not (0 <= age <= 120):
        raise HTTPException(422, detail="Âge hors bornes raisonnables (0–120).")
    if not (80 <= taille_cm_f <= 250):
        raise HTTPException(422, detail="Taille hors bornes raisonnables (80–250 cm).")
    if not (20 <= poids_kg_f <= 350):
        raise HTTPException(422, detail="Poids hors bornes raisonnables (20–350 kg).")

    # normalisation champs catégoriels
    sexe_norm = sexe.strip()
    if sexe_norm not in ("F", "M", "Autre"):
        sexe_norm = "Autre"
    activite_norm = activite.strip().lower()
    if activite_norm not in ("faible", "modérée", "moderee", "élevée", "elevee"):
        activite_norm = "modérée"
    # uniformise accents éventuels
    activite_norm = {"moderee":"modérée", "elevee":"élevée"}.get(activite_norm, activite_norm)

    # allergies JSON
    try:
        allergies_list = json.loads(allergies) if allergies else []
        if not isinstance(allergies_list, list):
            raise ValueError("allergies must be a JSON array")
        allergies_list = [str(x) for x in allergies_list]
    except Exception as e:
        raise HTTPException(400, detail=f"Allergies mal formées: {e}")

    profil = PatientProfile(
        age=age,
        sexe=sexe_norm,
        taille_cm=taille_cm_f,
        poids_kg=poids_kg_f,
        activite=activite_norm,
        objectifs=[],
        allergies=allergies_list,
        pathologies=[],
        medicaments=[],
    )
    payload = ConsultationIn(question=question, profil=profil)

    # RAG
    passages = await semantic_search(db, payload.question)
    if not passages:
        raise HTTPException(422, "Aucun contexte trouvé (ingérez vos cours).")

    # LLM
    prompt = build_prompt(payload.profil, payload.question, passages)
    try:
        brouillon = await generate_brouillon(prompt)
    except Exception as e:
        raise HTTPException(502, detail=f"LLM indisponible: {e}")

    warnings = nutrition_guardrails(brouillon, payload.profil)

    return {"statut": "draft", "brouillon": brouillon, "sources": passages, "warnings": warnings}