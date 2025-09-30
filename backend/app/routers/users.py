from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.deps import get_current_user
from app.db.session import get_db
from app.schemas.user import UserOut
router = APIRouter(prefix="/users", tags=["users"])
@router.get("/me", response_model=UserOut)
def me(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return {"id": user.id, "email": user.email, "plan": user.plan, "status": user.status}