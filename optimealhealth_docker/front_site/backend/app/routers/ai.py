from fastapi import APIRouter, Depends
from app.core.deps import get_current_user
from app.schemas.ai import ChatIn, ChatOut, SuggestMealsIn, SuggestMealsOut
router = APIRouter(prefix="/ai", tags=["ai"])
@router.post("/chat", response_model=ChatOut)
def ai_chat(payload: ChatIn, user=Depends(get_current_user)):
    return {"reply":"Stub IA (Docker): dÃ©mo OK.","suggested_actions":[{"type":"hydrate","value":"500ml eau"}]}
@router.post("/suggest-meals", response_model=SuggestMealsOut)
def ai_suggest(payload: SuggestMealsIn, user=Depends(get_current_user)):
    return {"meals":[{"day":"2025-09-24","breakfast":{"recipe_id":101,"title":"Porridge avoine","kcal":420},"lunch":{"recipe_id":202,"title":"Bowl quinoa lÃ©gumes","kcal":650},"dinner":{"recipe_id":303,"title":"Soupe lentilles corail","kcal":620},"total_kcal":1690,"notes":"Hydrate-toi bien"}], "warnings":[], "source":"ai_stub_docker"}