# app/routers/auth.py
from fastapi import APIRouter, Response, HTTPException
from pydantic import BaseModel

router = APIRouter()

class LoginForm(BaseModel):
    email: str
    password: str

@router.post("/auth/login")
def login(payload: LoginForm, response: Response):
    # 1) vérifier email/mdp...
    ok = (payload.email == "demo@user.tld" and payload.password == "demo")
    if not ok:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # 2) créer une session (exemple bidon)
    session_id = "demo_session_id"

    # 3) poser le cookie HttpOnly
    response.set_cookie(
        key="session",
        value=session_id,
        httponly=True,
        samesite="Lax",
        secure=False,      # True en prod HTTPS
        max_age=60*60,     # 1h
        path="/"
    )
    return {"ok": True}