from typing import Optional, Sequence, List, Dict, Any

# Version TEMPORAIRE ultra-sûre : ne requête pas la DB, évite toute erreur SQL.
async def hybrid_search(conn, query_embedding: Sequence[float], question: str,
                        top_k: int = 3, category: Optional[str] = None) -> List[Dict[str, Any]]:
    return []
