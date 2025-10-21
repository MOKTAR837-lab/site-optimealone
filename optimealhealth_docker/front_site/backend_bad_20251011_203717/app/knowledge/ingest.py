import asyncio, os, hashlib, httpx, asyncpg
from pathlib import Path
from app.knowledge.chunking import smart_chunk_text

async def embed(client, model, url, text):
    resp = await client.post(f"{url}/api/embeddings", json={"model": model, "prompt": text})
    return resp.json()["embedding"]

async def main():
    dsn = f"postgresql://{os.getenv(\"POSTGRES_USER\",\"postgres\")}:{os.getenv(\"POSTGRES_PASSWORD\",\"postgres\")}@{os.getenv(\"POSTGRES_HOST\",\"db\")}:{os.getenv(\"POSTGRES_PORT\",\"5432\")}/{os.getenv(\"POSTGRES_DB\",\"optimeal\")}"
    ollama_url = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
    embed_model = os.getenv("EMBED_MODEL", "nomic-embed-text")
    
    conn = await asyncpg.connect(dsn)
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            for name in os.listdir("/app/cours"):
                path = os.path.join("/app/cours", name)
                if not os.path.isfile(path):
                    continue
                print(f">>> {path}")
                with open(path, "r", encoding="utf-8-sig") as f:
                    text = f.read()
                sha = hashlib.sha256(text.encode()).hexdigest()
                doc_id = await conn.fetchval("INSERT INTO course_docs(path,sha256,topic,category,language) VALUES($1,$2,$3,$4,'fr') ON CONFLICT(sha256) DO UPDATE SET path=EXCLUDED.path RETURNING id", path, sha, name, "nutrition")
                for i, chunk_dict in enumerate(smart_chunk_text(text, Path(name).suffix)):
                    chunk_id = await conn.fetchval("INSERT INTO course_chunks(doc_id,ordinal,text,header) VALUES($1,$2,$3,$4) ON CONFLICT(doc_id,ordinal) DO UPDATE SET text=EXCLUDED.text RETURNING id", doc_id, i, chunk_dict["text"], chunk_dict.get("header"))
                    vec = await embed(client, embed_model, ollama_url, chunk_dict["text"])
                    await conn.execute("INSERT INTO course_embeddings(chunk_id,embedding,model_name) VALUES($1,$2::vector,$3) ON CONFLICT(chunk_id) DO UPDATE SET embedding=EXCLUDED.embedding", chunk_id, str(vec), embed_model)
            print("OK")
        finally:
            await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
