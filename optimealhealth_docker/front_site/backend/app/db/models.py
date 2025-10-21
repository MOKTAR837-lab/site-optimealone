from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from app.db.session import Base
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    plan = Column(String(50), nullable=True)
    status = Column(String(50), nullable=False, default="inactive")
    preferences = relationship("Preferences", back_populates="user", uselist=False, cascade="all, delete-orphan")
class Preferences(Base):
    __tablename__ = "preferences"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    diet = Column(String(50), nullable=True)
    allergies = Column(JSONB, nullable=False, default=list)
    exclude_ingredients = Column(JSONB, nullable=False, default=list)
    kcal_target_per_day = Column(Integer, nullable=True)
    goals = Column(JSONB, nullable=True)
    user = relationship("User", back_populates="preferences")