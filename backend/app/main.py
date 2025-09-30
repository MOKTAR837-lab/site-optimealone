from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.session import engine, Base, get_db

# Charger le modèle pour que Base.metadata.create_all connaisse la table
import app.models.client

# Importer les routeurs
from app.routers import clients

app = FastAPI(docs_url="/docs", redoc_url="/redoc", openapi_url="/openapi.json")

@app.on_event("startup")
async def on_startup():
    # Création des tables (temporaire ; en prod utiliser Alembic)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.on_event("shutdown")
async def on_shutdown():
    await engine.dispose()

# Publier les routes (niveau module, en dehors des fonctions)
app.include_router(clients.router)

@app.get("/")
async def root():
    return {"ok": True}

@app.get("/ping-db")
async def ping_db(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("SELECT 1"))
    return {"db": result.scalar_one()}

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}