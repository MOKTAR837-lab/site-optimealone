from typing import List, Dict

def reciprocal_rank_fusion(
    vector_results: List[Dict],
    bm25_results: List[Dict],
    k: int = 60
) -> List[Dict]:
    """
    Fusionne résultats vector et BM25 avec RRF
    Score RRF = 1 / (k + rank)
    """
    
    # Créer index par ID
    rrf_scores = {}
    
    # Scores vector
    for rank, result in enumerate(vector_results, 1):
        doc_id = result.get('chunk_id') or result.get('id')
        rrf_scores[doc_id] = rrf_scores.get(doc_id, 0) + 1 / (k + rank)
    
    # Scores BM25
    for rank, result in enumerate(bm25_results, 1):
        doc_id = result.get('chunk_id') or result.get('id')
        rrf_scores[doc_id] = rrf_scores.get(doc_id, 0) + 1 / (k + rank)
    
    # Merge données
    all_results = {r.get('chunk_id') or r.get('id'): r for r in vector_results + bm25_results}
    
    # Trier par score RRF
    ranked = []
    for doc_id, score in sorted(rrf_scores.items(), key=lambda x: x[1], reverse=True):
        if doc_id in all_results:
            result = all_results[doc_id].copy()
            result['rrf_score'] = score
            ranked.append(result)
    
    return ranked
