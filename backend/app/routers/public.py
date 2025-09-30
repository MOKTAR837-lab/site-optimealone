from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/api/v1/public", tags=["public"])

class ContactIn(BaseModel):
    name: str
    email: EmailStr
    message: str

@router.post("/contact", status_code=202)
async def contact(payload: ContactIn, background_tasks: BackgroundTasks):
    # plus tard: sauvegarde DB / envoi mail
    print("CONTACT:", payload.model_dump())
    return {"ok": True}
