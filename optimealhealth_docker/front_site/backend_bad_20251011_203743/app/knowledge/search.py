import asyncpg
from typing import List, Dict, Optional

async def hybrid_search(conn, query_embedding: List[float], query_text: str, top_k: int = 5, category: Optional[str] = None):
    await conn.execute("CREATE INDEX IF NOT EXISTS idx_fts ON course_chunks USING gin(to_tsvector('french', text));")
    
    filters = " AND cd.category = $3" if category else ""
    params_v = [str(query_embedding), top_k * 2]
    params_k = [query_text, top_k * 2]
    if category:
        params_v.append(category)
        params_k.append(category)
    
    vq = f"SELECT ce.chunk_id, cd.path, cd.category, cc.text, cc.header, 1-(ce.embedding<=>$1::vector) AS vs, ROW_NUMBER() OVER(ORDER BY ce.embedding<=> ::vector) AS vr FROM course_embeddings ce JOIN course_chunks cc ON ce.chunk_id=cc.id JOIN course_docs cd ON cc.doc_id=cd.id WHERE 1=1{filters} ORDER BY ce.embedding<=> ::vector LIMIT $2"
    
    kq = f"SELECT cc.id as chunk_id, cd.path, cd.category, cc.text, cc.header, ts_rank(to_tsvector('french',cc.text),plainto_tsquery('french',$1)) AS ks, ROW_NUMBER() OVER(ORDER BY ts_rank(to_tsvector('french',cc.text),plainto_tsquery('french', )) DESC) AS kr FROM course_chunks cc JOIN course_docs cd ON cc.doc_id=cd.id WHERE to_tsvector('french',cc.text)@@plainto_tsquery('french',$1){filters} ORDER BY ks DESC LIMIT  "
    
    vr = await conn.fetch(vq, *params_v)
    kr = await conn.fetch(kq, *params_k)
    
    scores = {}
    data = {}
    for r in vr:
        cid = r['chunk_id']
        scores[cid] = (1.0/(60+r['vr']))*0.7
        data[cid] = dict(r)
    for r in kr:
        cid = r['chunk_id']
        s = (1.0/(60+r['kr']))*0.3
        scores[cid] = scores.get(cid, 0) + s
        if cid not in data:
            data[cid] = dict(r)
    
    results = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:top_k]
    return [{'chunk_id': c, 'path': data[c]['path'], 'category': data[c].get('category'), 'text': data[c]['text'], 'header': data[c].get('header'), 'score': float(s)} for c, s in results]