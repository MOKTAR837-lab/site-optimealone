from __future__ import annotations
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Header, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.models.client import Client
from app.schemas.client import ClientCreate, ClientUpdate, ClientOut
from app.core.config import settings

router = APIRouter(prefix="/v1/clients", tags=["clients"])

async def require_api_key(x_api_key: str | None = Header(default=None, alias="X-API-Key")):
    if not settings.API_KEY:
        return  # dev: pas de clé configurée
    if x_api_key != settings.API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

@router.get("/", response_model=List[ClientOut])
@router.get("", response_model=List[ClientOut])  # accepte /clients et /clients/
async def list_clients(
    db: AsyncSession = Depends(get_db),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    res = await db.execute(select(Client).order_by(Client.created_at.desc()).limit(limit).offset(offset))
    return res.scalars().all()

@router.post("/", response_model=ClientOut, status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_api_key)])
@router.post("",  response_model=ClientOut, status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_api_key)])
async def create_client(payload: ClientCreate, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(Client).where(Client.email == payload.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Email already exists")
    obj = Client(name=payload.name, email=payload.email, phone=payload.phone)
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj

@router.patch("/{client_id}", response_model=ClientOut, dependencies=[Depends(require_api_key)])
async def update_client(client_id: str, payload: ClientUpdate, db: AsyncSession = Depends(get_db)):
    obj = await db.get(Client, client_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Client not found")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    await db.commit()
    await db.refresh(obj)
    return obj

@router.delete("/{client_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_api_key)])
async def delete_client(client_id: str, db: AsyncSession = Depends(get_db)):
    obj = await db.get(Client, client_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Client not found")
    await db.delete(obj)
    await db.commit()
    return None

