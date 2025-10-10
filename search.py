from typing import Optional, Sequence, List, Dict

VQUERY = """
SELECT
  title   AS path,
  title   AS header,
  content AS text,
  metadata,
  COALESCE(0.5 * (1 - (embedding <=> $1::vector)), 0) +
  0.5 * ts_rank_cd(search_tsv, plainto_tsquery('simple', $2)) AS score
FROM knowledge
WHERE ($3::text IS NULL OR metadata->>'category' = $3)
ORDER BY score DESC
LIMIT $4
"""

ATQUERY = """
SELECT
  title   AS path,
  title   AS header,
  content AS text,
  metadata,
  ts_rank_cd(search_tsv, plainto_tsquery('simple', $1)) AS score
FROM knowledge
WHERE ($2::text IS NULL OR metadata->>'category' = $2)
  AND search_tsv @@ plainto_tsquery('simple', $1)
ORDER BY score DESC
LIMIT $3
"""

async def hybrid_search(conn, query_embedding: Sequence[float], question: str, top_k: int = 3, category: Optional[str] = None) -> List[Dict]:
    # asyncpg + pgvector : passer le vecteur au format texte "[0.1,0.2,...]" pour ::vector
    emb_str = "[" + ",".join(str(x) for x in (query_embedding or [])) + "]"
    rows = await conn.fetch(VQUERY, emb_str, question, category, top_k)
    if not rows:
        rows = await conn.fetch(ATQUERY, question, category, top_k)
    return [
        {
            "path": r["path"],
            "header": r["header"],
            "text": r["text"],
            "metadata": r["metadata"],
            "score": float(r["score"]),
        } for r in rows
    ]
