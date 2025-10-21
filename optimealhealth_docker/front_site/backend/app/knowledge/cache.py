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
        return hashlib.md5(f"{normalized}:{model}".encode()).hexdigest()
    
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
            for key, _ in sorted_entries[:len(sorted_entries)//10]:
                del self.cache[key]
        key = self._hash_query(query, model)
        self.cache[key] = {'embedding': embedding, 'timestamp': datetime.now()}
    
    def stats(self) -> dict:
        total = self.hits + self.misses
        hit_rate = (self.hits / total * 100) if total > 0 else 0
        return {'size': len(self.cache), 'hits': self.hits, 'misses': self.misses, 'hit_rate': round(hit_rate, 2)}

_cache = None
def get_embedding_cache():
    global _cache
    if _cache is None:
        _cache = EmbeddingCache()
    return _cache