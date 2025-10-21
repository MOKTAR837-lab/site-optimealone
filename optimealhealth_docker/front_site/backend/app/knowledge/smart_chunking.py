import tiktoken
from typing import List, Dict

class SmartChunker:
    """Chunking intelligent avec overlap"""
    
    def __init__(self, chunk_size: int = 512, overlap: int = 50):
        self.chunk_size = chunk_size
        self.overlap = overlap
        self.encoding = tiktoken.get_encoding("cl100k_base")
    
    def count_tokens(self, text: str) -> int:
        return len(self.encoding.encode(text))
    
    def chunk_text(self, text: str, metadata: Dict = None) -> List[Dict]:
        """Découpe texte en chunks avec overlap"""
        tokens = self.encoding.encode(text)
        chunks = []
        
        start = 0
        chunk_id = 0
        
        while start < len(tokens):
            end = start + self.chunk_size
            chunk_tokens = tokens[start:end]
            chunk_text = self.encoding.decode(chunk_tokens)
            
            chunks.append({
                'text': chunk_text.strip(),
                'chunk_id': chunk_id,
                'start_token': start,
                'end_token': end,
                'token_count': len(chunk_tokens),
                'metadata': metadata or {}
            })
            
            chunk_id += 1
            start = end - self.overlap  # Overlap
        
        return chunks
    
    def chunk_by_sections(self, text: str, metadata: Dict = None) -> List[Dict]:
        """Découpe par sections avec headers"""
        sections = text.split('\n## ')  # Markdown headers
        all_chunks = []
        
        for i, section in enumerate(sections):
            if not section.strip():
                continue
                
            # Extrait header
            lines = section.split('\n', 1)
            header = lines[0].strip('#').strip()
            content = lines[1] if len(lines) > 1 else ""
            
            # Metadata enrichie
            section_meta = {
                **(metadata or {}),
                'header': header,
                'section_index': i
            }
            
            # Chunking du contenu
            if self.count_tokens(content) > self.chunk_size:
                chunks = self.chunk_text(content, section_meta)
            else:
                chunks = [{
                    'text': content.strip(),
                    'chunk_id': 0,
                    'token_count': self.count_tokens(content),
                    'metadata': section_meta
                }]
            
            all_chunks.extend(chunks)
        
        return all_chunks
