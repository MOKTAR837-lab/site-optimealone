# app/routers/consultation.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.consultation import ConsultationIn, ConsultationOut, SourceChunk
from app.services.rag import semantic_search
from app.services.prompting import build_prompt
from app.services.chat import generate_brouillon
from app.services.validators import nutrition_guardrails

router = APIRouter(prefix="/api/ai", tags=["ai"])

@router.post("/consultation", response_model=ConsultationOut)
async def consultation(payload: ConsultationIn, db: AsyncSession = Depends(get_db)):
    # 1) Récupérer les passages pertinents (RAG)
    passages = await semantic_search(db, payload.question)
    if not passages:
        raise HTTPException(422, "Aucun contexte trouvé (ingérez vos cours).")

    # 2) Construire le prompt
    prompt = build_prompt(payload.profil, payload.question, passages)

    # 3) Générer le brouillon via Ollama (chat model)
    try:
        brouillon = await generate_brouillon(prompt)
    except Exception as e:
        raise HTTPException(502, f"Erreur LLM: {e}")

    # 4) Valider automatiquement quelques règles (garde-fous)
    warnings = nutrition_guardrails(brouillon, payload.profil)

    # 5) Retourner un DRAFT (toujours en statut 'draft' pour relecture humaine)
    return ConsultationOut(
        statut="draft",
        brouillon=brouillon,
        sources=[SourceChunk(**p) for p in passages],
        warnings=warnings
    )