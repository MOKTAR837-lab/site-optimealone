from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.core.security import decode_token
from app.db.session import get_db
from app.db import crud
auth_scheme = HTTPBearer(auto_error=False)
def get_current_user(db: Session = Depends(get_db), token: HTTPAuthorizationCredentials = Depends(auth_scheme)):
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Non authentifiÃ©")
    payload = decode_token(token.credentials)
    uid = payload.get("sub")
    if not uid:
        raise HTTPException(status_code=401, detail="Token invalide")
    user = crud.get_user(db, int(uid))
    if not user:
        raise HTTPException(status_code=401, detail="Utilisateur introuvable")
    return user