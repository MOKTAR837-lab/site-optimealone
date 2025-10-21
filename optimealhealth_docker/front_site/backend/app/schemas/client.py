from __future__ import annotations
from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID
from datetime import datetime

class ClientBase(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

class ClientCreate(ClientBase):
    name: str
    email: EmailStr

class ClientUpdate(ClientBase):
    pass

class ClientOut(ClientBase):
    id: UUID
    created_at: datetime
    class Config:
        from_attributes = True
