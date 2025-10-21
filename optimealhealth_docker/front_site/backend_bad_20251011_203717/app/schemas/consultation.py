# app/schemas/consultation.py
from pydantic import BaseModel, Field
from typing import List, Optional

class PatientProfile(BaseModel):
    age: int
    sexe: str
    taille_cm: float
    poids_kg: float
    activite: str
    objectifs: List[str] = []
    allergies: List[str] = []
    pathologies: List[str] = []
    medicaments: List[str] = []

class ConsultationIn(BaseModel):
    question: str = Field(..., min_length=3)
    profil: PatientProfile

class SourceChunk(BaseModel):
    chunk_id: int
    source: str
    text: str

class WarningItem(BaseModel):
    code: str
    message: str

class ConsultationOut(BaseModel):
    statut: str   # "draft" toujours ici
    brouillon: str
    sources: List[SourceChunk]
    warnings: List[WarningItem] = []
2) Services utilitaires (pseudo-implémentations)
python
Copier le code
# app/services/embeddings.py
import os, httpx
from typing import List
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
EMBED_MODEL = os.getenv("EMBED_MODEL", "nomic-embed-text")

async def embed_query(q: str) -> List[float]:
    async with httpx.AsyncClient(timeout=60) as client:
        r = await client.post(f"{OLLAMA_URL}/api/embeddings",
                              json={"model": EMBED_MODEL, "prompt": q})
        r.raise_for_status()
        return r.json()["embedding"]

async def embed_texts(texts: List[str]) -> List[List[float]]:
    out = []
    async with httpx.AsyncClient(timeout=60) as client:
        for t in texts:
            r = await client.post(f"{OLLAMA_URL}/api/embeddings",
                                  json={"model": EMBED_MODEL, "prompt": t})
            r.raise_for_status()
            out.append(r.json()["embedding"])
    return out