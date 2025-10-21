import re
from typing import List, Dict

def smart_chunk_text(text: str, file_ext: str = 'txt') -> List[Dict]:
    chunk_size = 500
    overlap = 100
    if '\n\n' in text:
        paragraphs = [p.strip() for p in text.split('\n\n') if p.strip()]
        chunks = []
        current = []
        size = 0
        for p in paragraphs:
            if size + len(p) > chunk_size and current:
                chunks.append({'text': '\n\n'.join(current), 'header': None})
                current = [current[-1]] if overlap > 0 else []
                size = len(current[0]) if current else 0
            current.append(p)
            size += len(p)
        if current:
            chunks.append({'text': '\n\n'.join(current), 'header': None})
        return chunks
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    chunks = []
    current_chunk = []
    current_size = 0
    for sentence in sentences:
        if current_size + len(sentence) > chunk_size and current_chunk:
            chunks.append({'text': ' '.join(current_chunk), 'header': None})
            current_chunk = []
            current_size = 0
        current_chunk.append(sentence)
        current_size += len(sentence)
    if current_chunk:
        chunks.append({'text': ' '.join(current_chunk), 'header': None})
    return chunks