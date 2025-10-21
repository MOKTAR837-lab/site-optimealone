import math
from typing import List, Dict
from collections import Counter
import re

class BM25:
    """Okapi BM25 ranking"""
    
    def __init__(self, k1: float = 1.5, b: float = 0.75):
        self.k1 = k1
        self.b = b
        self.doc_freqs = []
        self.idf = {}
        self.doc_len = []
        self.avgdl = 0
        self.corpus_size = 0
    
    def tokenize(self, text: str) -> List[str]:
        """Tokenization simple"""
        text = text.lower()
        tokens = re.findall(r'\b\w+\b', text)
        return tokens
    
    def fit(self, corpus: List[str]):
        """Calcule IDF sur corpus"""
        self.corpus_size = len(corpus)
        
        # Fréquences documents
        df = Counter()
        for doc in corpus:
            tokens = set(self.tokenize(doc))
            df.update(tokens)
            
            doc_tokens = self.tokenize(doc)
            self.doc_freqs.append(Counter(doc_tokens))
            self.doc_len.append(len(doc_tokens))
        
        self.avgdl = sum(self.doc_len) / self.corpus_size if self.corpus_size > 0 else 0
        
        # IDF
        for term, freq in df.items():
            self.idf[term] = math.log((self.corpus_size - freq + 0.5) / (freq + 0.5) + 1)
    
    def score(self, query: str, doc_id: int) -> float:
        """Calcule score BM25 pour un document"""
        query_tokens = self.tokenize(query)
        doc_freqs = self.doc_freqs[doc_id]
        doc_len = self.doc_len[doc_id]
        
        score = 0.0
        for term in query_tokens:
            if term not in doc_freqs:
                continue
            
            freq = doc_freqs[term]
            idf = self.idf.get(term, 0)
            
            numerator = freq * (self.k1 + 1)
            denominator = freq + self.k1 * (1 - self.b + self.b * (doc_len / self.avgdl))
            
            score += idf * (numerator / denominator)
        
        return score
    
    def get_scores(self, query: str) -> List[float]:
        """Scores pour tous les documents"""
        return [self.score(query, i) for i in range(self.corpus_size)]
