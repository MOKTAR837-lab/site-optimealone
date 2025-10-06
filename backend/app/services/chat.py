# app/services/chat.py
import os, httpx
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
CHAT_MODEL = os.getenv("CHAT_MODEL", "llama3.1:8b")

async def generate_brouillon(prompt: str) -> str:
    async with httpx.AsyncClient(timeout=None) as client:
        r = await client.post(f"{OLLAMA_URL}/api/generate",
                              json={"model": CHAT_MODEL, "prompt": prompt, "stream": False})
        r.raise_for_status()
        return r.json().get("response", "")