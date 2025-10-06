# Script complet de déploiement RAG optimisé
# Usage: cd front_site puis .\deploy-complete-rag.ps1

Write-Host "=== Déploiement RAG Complet ===" -ForegroundColor Cyan

if (-not (Test-Path ".\backend")) {
    Write-Host "ERREUR: Exécutez depuis front_site" -ForegroundColor Red
    exit 1
}

function Write-FileSafely($Path, $Content) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
    Write-Host "  ✓ $(Split-Path -Leaf $Path)" -ForegroundColor Green
}

# ============================================
# 1. CHUNKING INTELLIGENT
# ============================================
Write-Host "`n[1/7] Chunking intelligent..." -ForegroundColor Yellow

$chunking = @'
import re
from typing import List, Dict

class SmartChunker:
    def __init__(self, chunk_size: int = 500, overlap: int = 100):
        self.chunk_size = chunk_size
        self.overlap = overlap
    
    def chunk_by_sentences(self, text: str) -> List[str]:
        text = text.strip()
        if not text:
            return []
        
        sentences = re.split(r'(?<=[.!?])\s+', text)
        chunks = []
        current_chunk = []
        current_size = 0
        
        for sentence in sentences:
            sentence_size = len(sentence)
            
            if current_size + sentence_size > self.chunk_size and current_chunk:
                chunks.append(' '.join(current_chunk))
                
                overlap_sentences = []
                overlap_size = 0
                for s in reversed(current_chunk):
                    if overlap_size + len(s) <= self.overlap:
                        overlap_sentences.insert(0, s)
                        overlap_size += len(s)
                    else:
                        break
                
                current_chunk = overlap_sentences
                current_size = overlap_size
            
            current_chunk.append(sentence)
            current_size += sentence_size
        
        if current_chunk:
            chunks.append(' '.join(current_chunk))
        
        return chunks
    
    def chunk_markdown(self, text: str) -> List[Dict]:
        lines = text.split('\n')
        sections = []
        current_section = {'header': '', 'level': 0, 'content': []}
        
        for line in lines:
            header_match = re.match(r'^(#{1,6})\s+(.+)$', line)
            
            if header_match:
                if current_section['content']:
                    sections.append(current_section)
                
                level = len(header_match.group(1))
                title = header_match.group(2)
                current_section = {'header': title, 'level': level, 'content': []}
            else:
                current_section['content'].append(line)
        
        if current_section['content']:
            sections.append(current_section)
        
        chunks = []
        for section in sections:
            content = '\n'.join(section['content']).strip()
            if content:
                chunk_text = f"# {section['header']}\n\n{content}" if section['header'] else content
                chunks.append({
                    'text': chunk_text,
                    'header': section['header'],
                    'level': section['level']
                })
        
        return chunks

def smart_chunk_text(text: str, file_ext: str = 'txt') -> List[Dict]:
    chunker = SmartChunker(chunk_size=500, overlap=100)
    
    if file_ext == '.md':
        return chunker.chunk_markdown(text)
    
    if '\n\n' in text:
        paragraphs = [p.strip() for p in text.split('\n\n') if p.strip()]
        chunks = []
        current = []
        size = 0
        
        for p in paragraphs:
            if size + len(p) > 500 and current:
                chunks.append({'text': '\n\n'.join(current), 'header': None})
                current = [current[-1]] if chunker.overlap > 0 else []
                size = len(current[0]) if current else 0
            current.append(p)
            size += len(p)
        
        if current:
            chunks.append({'text': '\n\n'.join(current), 'header': None})
        return chunks
    
    text_chunks = chunker.chunk_by_sentences(text)
    return [{'text': t, 'header': None} for t in text_chunks]
'@

Write-FileSafely -Path ".\backend\app\knowledge\chunking.py" -Content $chunking

# ============================================
# 2. CACHE EMBEDDINGS
# ============================================
Write-Host "`n[2/7] Cache embeddings..." -ForegroundColor Yellow

$cache = @'
import hashlib
from typing import Optional, List
from datetime import datetime, timedelta

class EmbeddingCache:
    def __init__(self, max_size: int = 1000, ttl_hours: int = 24):
        self.cache = {}
        self.max_size = max_size
        self.ttl = timedelta(hours=ttl_hours)
        self.hits = 0
        self.misses = 0
    
    def _hash_query(self, query: str, model: str) -> str:
        normalized = query.lower().strip()
        key_str = f"{normalized}:{model}"
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def get(self, query: str, model: str) -> Optional[List[float]]:
        key = self._hash_query(query, model)
        if key in self.cache:
            entry = self.cache[key]
            if datetime.now() - entry['timestamp'] < self.ttl:
                self.hits += 1
                return entry['embedding']
            del self.cache[key]
        self.misses += 1
        return None
    
    def set(self, query: str, model: str, embedding: List[float]):
        if len(self.cache) >= self.max_size:
            sorted_entries = sorted(self.cache.items(), key=lambda x: x[1]['timestamp'])
            to_remove = max(1, len(sorted_entries) // 10)
            for key, _ in sorted_entries[:to_remove]:
                del self.cache[key]
        
        key = self._hash_query(query, model)
        self.cache[key] = {'embedding': embedding, 'timestamp': datetime.now(), 'query': query}
    
    def stats(self) -> dict:
        total = self.hits + self.misses
        hit_rate = (self.hits / total * 100) if total > 0 else 0
        return {
            'size': len(self.cache),
            'max_size': self.max_size,
            'hits': self.hits,
            'misses': self.misses,
            'hit_rate': round(hit_rate, 2),
            'total_requests': total
        }
    
    def clear(self):
        self.cache = {}
        self.hits = 0
        self.misses = 0

_embedding_cache = None

def get_embedding_cache() -> EmbeddingCache:
    global _embedding_cache
    if _embedding_cache is None:
        _embedding_cache = EmbeddingCache(max_size=1000, ttl_hours=24)
    return _embedding_cache
'@

Write-FileSafely -Path ".\backend\app\knowledge\cache.py" -Content $cache

# ============================================
# 3. RECHERCHE HYBRIDE
# ============================================
Write-Host "`n[3/7] Recherche hybride..." -ForegroundColor Yellow

$search = @'
import asyncpg
from typing import List, Dict, Optional
from datetime import datetime

async def hybrid_search(
    conn: asyncpg.Connection, 
    query_embedding: List[float], 
    query_text: str, 
    top_k: int = 5,
    category: Optional[str] = None
) -> List[Dict]:
    
    # Créer l'index full-text s'il n'existe pas
    await conn.execute("CREATE INDEX IF NOT EXISTS idx_course_chunks_fts ON course_chunks USING gin(to_tsvector('french', text));")
    
    # Filtres
    filters = []
    params_vector = [str(query_embedding), top_k * 2]
    params_keyword = [query_text, top_k * 2]
    
    if category:
        filters.append("cd.category = $3")
        params_vector.append(category)
        params_keyword.append(category)
    
    where_clause = " AND " + " AND ".join(filters) if filters else ""
    
    # 1. Recherche vectorielle
    vector_query = f"""
        SELECT ce.chunk_id, cd.path, cd.category, cc.text, cc.header,
               1 - (ce.embedding <=> $1::vector) AS vector_score,
               ROW_NUMBER() OVER (ORDER BY ce.embedding <=> $1::vector) AS vector_rank
        FROM course_embeddings ce
        JOIN course_chunks cc ON ce.chunk_id = cc.id
        JOIN course_docs cd ON cc.doc_id = cd.id
        WHERE 1=1 {where_clause}
        ORDER BY ce.embedding <=> $1::vector
        LIMIT $2
    """
    
    vector_results = await conn.fetch(vector_query, *params_vector)
    
    # 2. Recherche mots-clés
    keyword_query = f"""
        SELECT cc.id as chunk_id, cd.path, cd.category, cc.text, cc.header,
               ts_rank(to_tsvector('french', cc.text), plainto_tsquery('french', $1)) AS keyword_score,
               ROW_NUMBER() OVER (ORDER BY ts_rank(to_tsvector('french', cc.text), plainto_tsquery('french', $1)) DESC) AS keyword_rank
        FROM course_chunks cc
        JOIN course_docs cd ON cc.doc_id = cd.id
        WHERE to_tsvector('french', cc.text) @@ plainto_tsquery('french', $1)
              {where_clause}
        ORDER BY keyword_score DESC
        LIMIT $2
    """
    
    keyword_results = await conn.fetch(keyword_query, *params_keyword)
    
    # 3. Fusion RRF (Reciprocal Rank Fusion)
    k = 60
    scores = {}
    data = {}
    
    for r in vector_results:
        chunk_id = r['chunk_id']
        scores[chunk_id] = (1.0 / (k + r['vector_rank'])) * 0.7
        data[chunk_id] = dict(r)
    
    for r in keyword_results:
        chunk_id = r['chunk_id']
        score = (1.0 / (k + r['keyword_rank'])) * 0.3
        if chunk_id in scores:
            scores[chunk_id] += score
        else:
            scores[chunk_id] = score
            data[chunk_id] = dict(r)
    
    # Trier et limiter
    sorted_results = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:top_k]
    
    return [
        {
            'chunk_id': cid,
            'path': data[cid]['path'],
            'category': data[cid].get('category'),
            'text': data[cid]['text'],
            'header': data[cid].get('header'),
            'score': float(score)
        }
        for cid, score in sorted_results
    ]
'@

Write-FileSafely -Path ".\backend\app\knowledge\search.py" -Content $search

# ============================================
# 4. INGEST.PY OPTIMISÉ
# ============================================
Write-Host "`n[4/7] Script d'ingestion optimisé..." -ForegroundColor Yellow

$ingest = @'
import asyncio, os, hashlib, httpx, asyncpg
from pathlib import Path
from app.knowledge.chunking import smart_chunk_text

async def embed(client, model, url, text):
    resp = await client.post(f"{url}/api/embeddings", json={"model": model, "prompt": text})
    return resp.json()["embedding"]

async def main():
    pg_user = os.getenv("POSTGRES_USER", "postgres")
    pg_pass = os.getenv("POSTGRES_PASSWORD", "postgres")
    pg_host = os.getenv("POSTGRES_HOST", "db")
    pg_port = os.getenv("POSTGRES_PORT", "5432")
    pg_db = os.getenv("POSTGRES_DB", "optimeal")
    
    dsn = f"postgresql://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}"
    ollama_url = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
    embed_model = os.getenv("EMBED_MODEL", "nomic-embed-text")
    
    courses_dir = "/app/cours"
    
    print(f"DSN: {pg_host}:{pg_port}/{pg_db}")
    print(f"Ollama: {ollama_url} | model={embed_model}")
    print(f"Courses: {courses_dir}\n")
    
    conn = await asyncpg.connect(dsn)
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            for name in os.listdir(courses_dir):
                path = os.path.join(courses_dir, name)
                if not os.path.isfile(path):
                    continue
                
                print(f">>> DOC: {path}")
                
                # Lire avec UTF-8-sig pour supprimer BOM
                with open(path, "r", encoding="utf-8-sig") as f:
                    text = f.read()
                
                sha = hashlib.sha256(text.encode("utf-8")).hexdigest()
                file_ext = Path(name).suffix
                
                # Extraire métadonnées basiques
                category = "nutrition"  # Par défaut, à améliorer avec détection
                
                # Upsert document
                doc_id = await conn.fetchval("""
                    INSERT INTO course_docs(path, sha256, topic, category, language)
                    VALUES($1, $2, $3, $4, $5)
                    ON CONFLICT(sha256) DO UPDATE SET path=EXCLUDED.path
                    RETURNING id
                """, path, sha, name, category, "fr")
                
                print(f"  doc_id={doc_id}")
                
                # Chunking intelligent
                chunks_data = smart_chunk_text(text, file_ext)
                print(f"  chunks={len(chunks_data)}")
                
                for i, chunk_dict in enumerate(chunks_data):
                    chunk_text = chunk_dict['text']
                    header = chunk_dict.get('header')
                    
                    # Insérer chunk avec header
                    chunk_id = await conn.fetchval("""
                        INSERT INTO course_chunks(doc_id, ordinal, text, header)
                        VALUES($1, $2, $3, $4)
                        ON CONFLICT(doc_id, ordinal) DO UPDATE SET text=EXCLUDED.text, header=EXCLUDED.header
                        RETURNING id
                    """, doc_id, i, chunk_text, header)
                    
                    print(f"    chunk_id={chunk_id} (ord={i}, header={header})")
                    
                    # Générer embedding
                    vec = await embed(client, embed_model, ollama_url, chunk_text)
                    
                    # Insérer embedding
                    await conn.execute("""
                        INSERT INTO course_embeddings(chunk_id, embedding, model_name)
                        VALUES($1, $2::vector, $3)
                        ON CONFLICT(chunk_id) DO UPDATE SET embedding=EXCLUDED.embedding, model_name=EXCLUDED.model_name
                    """, chunk_id, str(vec), embed_model)
                    
                    print("    embedding OK")
                
                print()
            
            print("✅ Ingestion terminée")
        
        finally:
            await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
'@

Write-FileSafely -Path ".\backend\app\knowledge\ingest.py" -Content $ingest

# ============================================
# 5. MIGRATION MÉTADONNÉES
# ============================================
Write-Host "`n[5/7] Migration métadonnées..." -ForegroundColor Yellow

$migration = @'
from alembic import op

revision = "0002_add_metadata_fields"
down_revision = "0001_init_pgvector_knowledge"
branch_labels = None
depends_on = None

def upgrade():
    op.execute("""
        ALTER TABLE course_docs 
        ADD COLUMN IF NOT EXISTS category TEXT,
        ADD COLUMN IF NOT EXISTS author TEXT,
        ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'fr',
        ADD COLUMN IF NOT EXISTS published_at TIMESTAMP;
    """)
    
    op.execute("""
        ALTER TABLE course_chunks
        ADD COLUMN IF NOT EXISTS header TEXT;
    """)
    
    op.execute("""
        ALTER TABLE course_embeddings
        ADD COLUMN IF NOT EXISTS model_name TEXT DEFAULT 'nomic-embed-text',
        ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();
    """)
    
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_docs_category ON course_docs(category) WHERE category IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_chunks_header ON course_chunks(header) WHERE header IS NOT NULL;")

def downgrade():
    op.execute("DROP INDEX IF EXISTS idx_course_chunks_header;")
    op.execute("DROP INDEX IF EXISTS idx_course_docs_category;")
    op.execute("ALTER TABLE course_embeddings DROP COLUMN IF EXISTS created_at, DROP COLUMN IF EXISTS model_name;")
    op.execute("ALTER TABLE course_chunks DROP COLUMN IF EXISTS header;")
    op.execute("ALTER TABLE course_docs DROP COLUMN IF EXISTS published_at, DROP COLUMN IF EXISTS language, DROP COLUMN IF EXISTS author, DROP COLUMN IF EXISTS category;")
'@

Write-FileSafely -Path ".\backend\alembic\versions\0002_add_metadata_fields.py" -Content $migration

# ============================================
# 6. MAIN.PY COMPLET
# ============================================
Write-Host "`n[6/7] main.py complet..." -ForegroundColor Yellow

$main = @'
from fastapi import FastAPI, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import httpx, asyncpg, os
from typing import Optional
from datetime import datetime

from app.db.session import engine, get_db
from app.db.base import Base
from app.models import client as _
from app.routers import clients
from app.knowledge.cache import get_embedding_cache
from app.knowledge.search import hybrid_search

app = FastAPI(title="Optimeal API", version="0.2.0", root_path="/api", docs_url="/docs", redoc_url="/redoc", openapi_url="/openapi.json")

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

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/cache/stats")
async def cache_stats():
    cache = get_embedding_cache()
    return cache.stats()

@app.delete("/cache")
async def clear_cache():
    cache = get_embedding_cache()
    cache.clear()
    return {"status": "cache cleared"}

@app.post("/search")
async def search_knowledge(
    query: str,
    top_k: int = Query(default=5, ge=1, le=20),
    use_hybrid: bool = True,
    category: Optional[str] = None
):
    ollama_url = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
    embed_model = os.getenv("EMBED_MODEL", "nomic-embed-text")
    cache = get_embedding_cache()
    
    query_embedding = cache.get(query, embed_model)
    
    if query_embedding is None:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(f"{ollama_url}/api/embeddings", json={"model": embed_model, "prompt": query})
            query_embedding = resp.json()["embedding"]
        cache.set(query, embed_model, query_embedding)
    
    dsn = f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}"
    
    conn = await asyncpg.connect(dsn)
    try:
        if use_hybrid:
            results = await hybrid_search(conn, query_embedding, query, top_k, category)
        else:
            query_sql = """
                SELECT cd.path, cd.category, cc.text, cc.header, 1 - (ce.embedding <=> $1::vector) AS score
                FROM course_embeddings ce
                JOIN course_chunks cc ON ce.chunk_id = cc.id
                JOIN course_docs cd ON cc.doc_id = cd.id
                WHERE ($3::text IS NULL OR cd.category = $3)
                ORDER BY ce.embedding <=> $1::vector
                LIMIT $2
            """
            results_raw = await conn.fetch(query_sql, str(query_embedding), top_k, category)
            results = [{"path": r["path"], "category": r["category"], "text": r["text"], "header": r["header"], "score": float(r["score"])} for r in results_raw]
    finally:
        await conn.close()
    
    return {"query": query, "results": results, "count": len(results)}

@app.post("/ask")
async def ask_with_context(
    question: str,
    top_k: int = Query(default=3, ge=1, le=10),
    model: str = "llama3.2",
    category: Optional[str] = None
):
    ollama_url = os.getenv("OLLAMA_URL", "http://host.docker.internal:11434")
    embed_model = os.getenv("EMBED_MODEL", "nomic-embed-text")
    cache = get_embedding_cache()
    
    query_embedding = cache.get(question, embed_model)
    if query_embedding is None:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(f"{ollama_url}/api/embeddings", json={"model": embed_model, "prompt": question})
            query_embedding = resp.json()["embedding"]
        cache.set(question, embed_model, query_embedding)
    
    dsn = f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}"
    
    conn = await asyncpg.connect(dsn)
    try:
        results = await hybrid_search(conn, query_embedding, question, top_k, category)
    finally:
        await conn.close()
    
    if not results:
        return {"question": question, "answer": "Aucun document trouvé pour répondre à cette question.", "sources": []}
    
    context = "\n\n".join([f"[{r['path']}]\n{r['text']}" for r in results])
    prompt = f"""Tu es un assistant nutritionniste expert. Réponds à la question en te basant UNIQUEMENT sur le contexte fourni.

Contexte documentaire:
{context}

Question: {question}

Réponse (en français, claire et structurée):"""

    async with httpx.AsyncClient(timeout=60.0) as client:
        resp = await client.post(f"{ollama_url}/api/generate", json={"model": model, "prompt": prompt, "stream": False})
        answer = resp.json()["response"]
    
    return {"question": question, "answer": answer, "sources": results, "count": len(results)}
'@

Write-FileSafely -Path ".\backend\app\main.py" -Content $main

# ============================================
# 7. DÉPLOIEMENT
# ============================================
Write-Host "`n[7/7] Déploiement..." -ForegroundColor Yellow

Write-Host "  Arrêt des conteneurs..." -ForegroundColor Gray
docker compose -f docker-compose.prod.yml down 2>$null

Write-Host "  Build et démarrage..." -ForegroundColor Gray
docker compose -f docker-compose.prod.yml up -d --build

Write-Host "  Attente 20s..." -ForegroundColor Gray
Start-Sleep -Seconds 20

Write-Host "  Migration Alembic..." -ForegroundColor Gray
docker compose -f docker-compose.prod.yml exec api alembic upgrade head

# ============================================
# TESTS
# ============================================
Write-Host "`n=== Tests ===" -ForegroundColor Cyan

try {
    $h = Invoke-WebRequest -Uri "http://localhost/health" -UseBasicParsing
    Write-Host "✓ Health: $($h.StatusCode)" -ForegroundColor Green
} catch { Write-Host "✗ Health: $_" -ForegroundColor Red }

try {
    $c = Invoke-WebRequest -Uri "http://localhost/cache/stats" -UseBasicParsing
    $stats = $c.Content | ConvertFrom-Json
    Write-Host "✓ Cache: $($stats.size) entrées, $($stats.hit_rate)% hits" -ForegroundColor Green
} catch { Write-Host "✗ Cache: $_" -ForegroundColor Red }

try {
    $s = Invoke-WebRequest -Uri "http://localhost/search?query=test&top_k=2&use_hybrid=true" -Method POST -UseBasicParsing
    Write-Host "✓ Hybrid search: $($s.StatusCode)" -ForegroundColor Green
} catch { Write-Host "✗ Search: $_" -ForegroundColor Red }

Write-Host "`n=== Déploiement terminé ===" -ForegroundColor Cyan
Write-Host "`nOptimisations actives:" -ForegroundColor White
Write-Host "  ✓ Chunking intelligent avec overlap (500 chars, 100 overlap)" -ForegroundColor Green
Write-Host "  ✓ Cache embeddings (1000 max, 24h TTL)" -ForegroundColor Green
Write-Host "  ✓ Recherche hybride vectorielle + full-text (70/30)" -ForegroundColor Green
Write-Host "  ✓ Métadonnées: category, author, header, language" -ForegroundColor Green
Write-Host "  ✓ Filtrage par catégorie" -ForegroundColor Green
Write-Host "`nEndpoints:" -ForegroundColor White
Write-Host "  http://localhost/docs" -ForegroundColor Gray
Write-Host "  http://localhost/cache/stats" -ForegroundColor Gray
Write-Host "  http://localhost/search?query=XXX&category=nutrition" -ForegroundColor Gray
Write-Host "  http://localhost/ask (POST JSON)" -ForegroundColor Gray
Write-Host "`nRéingestion recommandée:" -ForegroundColor Yellow
Write-Host "  docker compose -f docker-compose.prod.yml exec api python -m app.knowledge.ingest" -ForegroundColor Gray