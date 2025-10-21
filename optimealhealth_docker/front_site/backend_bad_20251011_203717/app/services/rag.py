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