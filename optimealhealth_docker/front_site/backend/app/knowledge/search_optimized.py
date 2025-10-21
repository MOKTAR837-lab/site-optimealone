import asyncpg
from typing import List, Dict, Optional
from app.knowledge.bm25 import BM25
from app.knowledge.rrf import reciprocal_rank_fusion

async def hybrid_search_optimized(
    conn: asyncpg.Connection,
    query_embedding: List[float],
    query_text: str,
    top_k: int = 5,
    category: Optional[str] = None,
    use_rrf: bool = True
) -> List[Dict]:
    """
    Recherche hybride optimisée avec BM25 + RRF
    """
    
    # 1. Recherche vectorielle
    vector_query = """
        SELECT 
            ce.chunk_id,
            cc.text,
            cc.header,
            cd.path,
            cd.category,
            1 - (ce.embedding <=> $1::vector) AS vector_score
        FROM course_embeddings ce
        JOIN course_chunks cc ON ce.chunk_id = cc.id
        JOIN course_docs cd ON cc.doc_id = cd.id
        WHERE ($3::text IS NULL OR cd.category = $3)
        ORDER BY ce.embedding <=> $1::vector
        LIMIT $2
    """
    
    vector_results = await conn.fetch(
        vector_query,
        str(query_embedding),
        top_k * 2,  # Plus de résultats pour fusion
        category
    )
    
    # 2. Recherche full-text PostgreSQL
    fts_query = """
        SELECT 
            cc.id as chunk_id,
            cc.text,
            cc.header,
            cd.path,
            cd.category,
            ts_rank(cc.fts, websearch_to_tsquery('french', $1)) AS fts_score
        FROM course_chunks cc
        JOIN course_docs cd ON cc.doc_id = cd.id
        WHERE cc.fts @@ websearch_to_tsquery('french', $1)
          AND ($3::text IS NULL OR cd.category = $3)
        ORDER BY fts_score DESC
        LIMIT $2
    """
    
    fts_results = await conn.fetch(
        fts_query,
        query_text,
        top_k * 2,
        category
    )
    
    # Conversion en dicts
    vector_dicts = [dict(r) for r in vector_results]
    fts_dicts = [dict(r) for r in fts_results]
    
    # 3. Fusion RRF
    if use_rrf and len(vector_dicts) > 0 and len(fts_dicts) > 0:
        results = reciprocal_rank_fusion(vector_dicts, fts_dicts, k=60)
    elif len(vector_dicts) > 0:
        results = vector_dicts
    else:
        results = fts_dicts
    
    # 4. Limitation finale
    results = results[:top_k]
    
    # 5. Format final
    final = []
    for r in results:
        final.append({
            'path': r.get('path', ''),
            'category': r.get('category', ''),
            'text': r.get('text', ''),
            'header': r.get('header', ''),
            'score': r.get('rrf_score', r.get('vector_score', r.get('fts_score', 0)))
        })
    
    return final
