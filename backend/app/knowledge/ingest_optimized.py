import asyncio
import asyncpg
import httpx
import os
from pathlib import Path
from app.knowledge.smart_chunking import SmartChunker

async def ingest_optimized():
    """Ingestion optimisée avec chunking intelligent"""
    
    # Config
    ollama_url = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
    embed_model = os.getenv("EMBED_MODEL", "nomic-embed-text")
    
    # DB
    user = os.getenv("POSTGRES_USER")
    password = os.getenv("POSTGRES_PASSWORD")
    host = os.getenv("POSTGRES_HOST")
    port = os.getenv("POSTGRES_PORT")
    db = os.getenv("POSTGRES_DB")
    dsn = f"postgresql://{user}:{password}@{host}:{port}/{db}"
    
    conn = await asyncpg.connect(dsn)
    
    # Chunker
    chunker = SmartChunker(chunk_size=512, overlap=50)
    
    # Documents
    cours_dir = Path("cours")
    
    if not cours_dir.exists():
        print("❌ Dossier cours/ introuvable")
        return
    
    try:
        for md_file in cours_dir.rglob("*.md"):
            print(f"📄 {md_file.name}")
            
            content = md_file.read_text(encoding='utf-8')
            category = md_file.parent.name
            
            # Métadonnées
            metadata = {
                'file': md_file.name,
                'category': category
            }
            
            # Chunking par sections
            chunks = chunker.chunk_by_sections(content, metadata)
            
            # Insert document
            doc_id = await conn.fetchval(
                "INSERT INTO course_docs (path, category) VALUES ($1, $2) RETURNING id",
                str(md_file),
                category
            )
            
            # Insert chunks + embeddings
            async with httpx.AsyncClient(timeout=30.0) as client:
                for chunk in chunks:
                    # Embedding
                    resp = await client.post(
                        f"{ollama_url}/api/embeddings",
                        json={"model": embed_model, "prompt": chunk['text']}
                    )
                    embedding = resp.json()["embedding"]
                    
                    # Insert chunk
                    chunk_id = await conn.fetchval(
                        "INSERT INTO course_chunks (doc_id, text, header, token_count) VALUES ($1, $2, $3, $4) RETURNING id",
                        doc_id,
                        chunk['text'],
                        chunk['metadata'].get('header', ''),
                        chunk['token_count']
                    )
                    
                    # Insert embedding
                    await conn.execute(
                        "INSERT INTO course_embeddings (chunk_id, embedding) VALUES ($1, $2)",
                        chunk_id,
                        str(embedding)
                    )
            
            print(f"   ✅ {len(chunks)} chunks")
    
    finally:
        await conn.close()
    
    print("\n✅ Ingestion terminée !")

if __name__ == "__main__":
    asyncio.run(ingest_optimized())
