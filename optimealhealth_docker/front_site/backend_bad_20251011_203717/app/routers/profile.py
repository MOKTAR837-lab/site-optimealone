from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.session import get_db
from app.db import crud
from app.schemas.profile import Preferences
router = APIRouter(prefix="/profile", tags=["profile"])
@router.get("/preferences", response_model=Preferences)
def get_prefs(db: Session = Depends(get_db), user=Depends(get_current_user)):
    p = crud.get_preferences(db, user.id)
    return Preferences.model_validate(p.__dict__, from_attributes=True) if p else Preferences()
@router.put("/preferences", response_model=Preferences)
def set_prefs(payload: Preferences, db: Session = Depends(get_db), user=Depends(get_current_user)):
    p = crud.set_preferences(db, user.id, payload.model_dump(exclude_unset=True))
    return Preferences.model_validate(p.__dict__, from_attributes=True)