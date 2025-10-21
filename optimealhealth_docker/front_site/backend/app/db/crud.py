from sqlalchemy.orm import Session
from passlib.hash import bcrypt
from app.db import models
def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()
def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()
def create_user(db: Session, email: str, password: str):
    u = models.User(email=email, password_hash=bcrypt.hash(password), status="inactive")
    db.add(u); db.commit(); db.refresh(u)
    return u
def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.verify(password, password_hash)
def get_preferences(db: Session, user_id: int):
    return db.query(models.Preferences).filter(models.Preferences.user_id == user_id).first()
def set_preferences(db: Session, user_id: int, prefs: dict):
    p = get_preferences(db, user_id)
    if p is None:
        p = models.Preferences(user_id=user_id); db.add(p)
    for k, v in prefs.items(): setattr(p, k, v)
    db.commit(); db.refresh(p); return p