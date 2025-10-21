from typing import Optional
import os, httpx, asyncpg
from fastapi import FastAPI, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings
from app.db.session import engine, get_db
from app.db.base import Base
from app.models import client as _  # force import modÃ¨les
from app.routers import clients
from app.knowledge.cache import get_embedding_cache
from app.knowledge.search import hybrid_search

app = FastAPI(
    title="Optimeal API",
    version="0.2.0",
    root_path="/api",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS depuis ENV uniquement
origins_csv = os.getenv("CORS_ORIGINS","http://localhost:3000,http://127.0.0.1:3000,http://localhost:4321,http://127.0.0.1:4321")
origins = [o.strip() for o in origins_csv.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.on_event("shutdown")
async def on_shutdown():
    await engine.dispose()

app.include_router(clients.router)

@app.get("/")
async def root():
    return {"ok": True, "version": "0.2.0"}

@app.get("/ping-db")
async def ping_db(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("SELECT 1"))
    return {"db": result.scalar_one()}

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/cache/stats")
async def cache_stats():
    return get_embedding_cache().stats()

@app.post("/search")
async def search_knowledge(
    query: str,
    top_k: int = Query(default=5, ge=1, le=20),
    use_hybrid: bool = True,
    category: Optional[str] = None,
):
    ollama_url = getattr(settings, "ollama_url", None) or os.getenv("OLLAMA_URL") or "http://host.docker.internal:11434"
    embed_model = os.getenv("EMBED_MODEL", "nomic-embed-text")
    cache = get_embedding_cache()
    query_embedding = cache.get(query, embed_model)
    if query_embedding is None:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(f"{ollama_url}/api/embeddings", json={"model": embed_model, "prompt": query})
            resp.raise_for_status()
            query_embedding = resp.json()["embedding"]
        cache.set(query, embed_model, query_embedding)
    dsn = (
        os.getenv("ASYNC_PG_DSN")
        or (os.getenv("DATABASE_URL") or "").replace("+asyncpg","")
        or "postgresql://postgres:postgres@db:5432/nutrition"
    )
    conn = await asyncpg.connect(dsn)
    try:
        results = await hybrid_search(conn, query_embedding, query, top_k, category)
    finally:
        await conn.close()
    return {"query": query, "top_k": top_k, "results": results}