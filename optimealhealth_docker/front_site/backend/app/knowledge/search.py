import asyncpg

async def hybrid_search(conn, query_embedding, question, top_k=5, category=None):
    await conn.execute("CREATE INDEX IF NOT EXISTS idx_fts ON course_chunks USING gin(to_tsvector('french', text));")
    
    # Recherche sémantique (vectorielle)
    vq = """
    SELECT c.id, c.text, c.header, d.path, d.category,
           1 - (e.embedding <=> $1::vector) as score
    FROM course_chunks c
    JOIN course_docs d ON c.doc_id = d.id
    JOIN course_embeddings e ON e.chunk_id = c.id
    WHERE ($2::text IS NULL OR d.category = $2)
    ORDER BY e.embedding <=> $1::vector
    LIMIT $3
    """
    
    params_v = [str(query_embedding), category, top_k]
    vr = await conn.fetch(vq, *params_v)
    
    # Recherche full-text
    fq = """
    SELECT c.id, c.text, c.header, d.path, d.category,
           ts_rank(to_tsvector('french', c.text), plainto_tsquery('french', $1)) as score
    FROM course_chunks c
    JOIN course_docs d ON c.doc_id = d.id
    WHERE to_tsvector('french', c.text) @@ plainto_tsquery('french', $1)
      AND ($2::text IS NULL OR d.category = $2)
    ORDER BY score DESC
    LIMIT $3
    """
    
    params_f = [question, category, top_k]
    fr = await conn.fetch(fq, *params_f)
    
    # Fusion (Reciprocal Rank Fusion)
    scores = {}
    for i, row in enumerate(vr):
        scores[row['id']] = {'data': row, 'score': 0.8 / (i + 1)}
    for i, row in enumerate(fr):
        if row['id'] in scores:
            scores[row['id']]['score'] += 0.2 / (i + 1)
        else:
            scores[row['id']] = {'data': row, 'score': 0.2 / (i + 1)}
    
    results = sorted(scores.values(), key=lambda x: x['score'], reverse=True)[:top_k]
    
    return [{'id': r['data']['id'], 
             'text': r['data']['text'], 
             'header': r['data']['header'],
             'path': r['data']['path'],
             'category': r['data']['category'],
             'score': r['score']} for r in results]
