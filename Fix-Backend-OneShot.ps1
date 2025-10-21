
$ErrorActionPreference="Stop"
$ROOT = (Get-Location).Path

function WriteUtf8($p,$c){
  $d=Split-Path -Parent $p; if($d){New-Item -ItemType Directory -Force -Path $d|Out-Null}
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($p,$c,$enc)
}

# 1) Supprimer override et Dockerfile du dossier backend (ambiguïtés)
Remove-Item "$ROOT\docker-compose.override.yml" -Force -ErrorAction Ignore
if(Test-Path "$ROOT\backend\Dockerfile"){ Rename-Item "$ROOT\backend\Dockerfile" "$ROOT\backend\Dockerfile.disabled" -Force }

# 2) Dockerfile (RACINE) — copie uniquement backend/ et écoute 0.0.0.0
$dockerfile = @'
FROM python:3.12-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ .
EXPOSE 8000
CMD ["uvicorn","app.main:app","--host","0.0.0.0","--port","8000"]
'@
WriteUtf8 "$ROOT\Dockerfile" $dockerfile

# 3) backend/app/main.py — CORS via ENV uniquement, root_path=/api
$mainpy = @'
from typing import Optional
import os, httpx, asyncpg
from fastapi import FastAPI, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings
from app.db.session import engine, get_db
from app.db.base import Base
from app.models import client as _  # force import modèles
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
'@
WriteUtf8 "$ROOT\backend\app\main.py" $mainpy

# 4) docker-compose.yml propre (RACINE)
$compose = @'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: nutrition
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7

  backend:
    build:
      context: .
      dockerfile: Dockerfile
    env_file:
      - ./backend/.env
    environment:
      DATABASE_URL: postgresql+asyncpg://postgres:postgres@db:5432/nutrition
      ASYNC_PG_DSN: postgresql://postgres:postgres@db:5432/nutrition
      CORS_ORIGINS: http://localhost:3000,http://127.0.0.1:3000,http://localhost:4321,http://127.0.0.1:4321
    depends_on:
      - db
      - redis
    ports:
      - "8000:8000"
volumes:
  pgdata:
'@
WriteUtf8 "$ROOT\docker-compose.yml" $compose

# 5) Restart propre
docker compose down --remove-orphans | Out-Null
docker compose build --no-cache backend
docker compose up -d

Start-Sleep -Seconds 3
Write-Host "`n=== docker compose ps ==="
docker compose ps

Write-Host "`n=== Logs backend (60 lignes) ==="
docker compose logs --tail=60 backend

# 6) Tests internes et externes
$cid = (docker compose ps -q backend).Trim()
if($cid){
  Write-Host "`n=== Test interne depuis le conteneur ==="
  docker exec $cid python -c "import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:8000/api/health',timeout=5).status)"
}

Write-Host "`n=== Test externe depuis l'hôte ==="
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "api/health:%{http_code}`n" http://localhost:8000/api/health
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "api/docs:%{http_code}`n" http://localhost:8000/api/docs
& "$Env:SystemRoot\System32\curl.exe" -s -o NUL -w "root:%{http_code}`n" http://localhost:8000/
