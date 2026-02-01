
from sqlalchemy.orm import Session
from api.models.chunks import Chunk
from api.models.lecture_notes import LectureNote
from api.utils.embedding_utils import generate_embedding
import numpy as np

def bytes_to_vector(blob: bytes) -> np.ndarray:
    """Convert MySQL LONGBLOB back to numpy float32 vector."""
    if not blob:
        return np.array([])
    return np.frombuffer(blob, dtype=np.float32)

def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Compute cosine similarity between two vectors."""
    if a.size == 0 or b.size == 0:
        return 0.0
    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(np.dot(a, b) / (norm_a * norm_b))

def search_lecture_chunks(db: Session, lecture_note_id: int, query: str, top_k: int = 6):
    """
    Performs vector search on chunks identified by lecture_note_id.
    Returns top_k chunks sorted by similarity.
    """
    # Generate embedding for the query
    query_bytes = generate_embedding(query)
    if not query_bytes:
        return []
    
    query_vec = np.frombuffer(query_bytes, dtype=np.float32)

    # Fetch chunks
    chunks = db.query(Chunk).filter(Chunk.lecture_notes_id == lecture_note_id).all()
    if not chunks:
        return []

    similarities = []
    
    for chunk in chunks:
        if not chunk.embedding:
            continue
        
        chunk_vec = bytes_to_vector(chunk.embedding)
        sim = cosine_similarity(query_vec, chunk_vec)
        
        similarities.append((chunk, sim))

    # Sort by similarity desc
    similarities.sort(key=lambda x: x[1], reverse=True)
    
    # Return top K chunks (just the models)
    return [item[0] for item in similarities[:top_k]]
