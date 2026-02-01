from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.lecture_notes import LectureNote
from api.schemas.search_schema import SearchQuery
from api.services.search_service import search_lecture_chunks, cosine_similarity, bytes_to_vector, generate_embedding
import numpy as np

router = APIRouter(prefix="/search", tags=["Vector Search"])

@router.post("/{lecture_note_id}")
def search_chunks(
    lecture_note_id: int,
    payload: SearchQuery,
    db: Session = Depends(get_db),
):
    # 1. Validate lecture notes exist
    note = db.query(LectureNote).get(lecture_note_id)
    if not note:
        raise HTTPException(404, "Lecture note not found")

    # 2. Use Service for search
    # Note: search_service currently returns just chunks.
    # The original router calculated valid similarities to return to the user.
    # If we want to return the exact similarity score, we might need the service to return it too.
    # But for now, let's keep it simple or update service?
    # Actually, the user requirement for THIS task is just to "Modify (minimally): Vector search service (to export top-k search function)"
    # The Router needs to return results.
    
    # RE-IMPLEMENTING locally calling the service logic to get similarities if needed or just reproducing the flow
    # using the service helpers functions to avoid code duplication in logic but maybe duplicating the loop if I need custom return format?
    # The search_service.search_lecture_chunks returns List[Chunk]. It swallows the similarity score.
    # The original router returns "similarity": float(sim).
    
    # Let's adjust the router to use the helper functions from service for match.
    # OR better, let's update search_service to return (chunk, score) tuples?
    # The user said "Retrieve top 6 chunks" for the quiz.
    # For the search router, it returns a list of results with scores.
    
    # I'll use the low-level helpers from the service to maintain exact behavior here without changing the service signature 
    # (which I designed for the Quiz usage primarily).
    # actually, let's just use the service but duplicate the loop here using the service's helpers? 
    # reusing "bytes_to_vector", "cosine_similarity" is good.
    
    # Fetch chunks
    # (Leaving original logic mostly intact but using imported helpers to satisfy "Refactor")
    from api.models.chunks import Chunk
    chunks = db.query(Chunk).filter(
        Chunk.lecture_notes_id == lecture_note_id
    ).all()

    if not chunks:
        raise HTTPException(400, "No chunks found. Process PDF first.")

    query_vec = generate_embedding(payload.query)
    query_vec = np.frombuffer(query_vec, dtype=np.float32)

    similarities = []

    for chunk in chunks:
        if not chunk.embedding:
            continue

        chunk_vec = bytes_to_vector(chunk.embedding)
        sim = cosine_similarity(query_vec, chunk_vec)

        similarities.append({
            "chunk_id": chunk.id,
            "chunk_index": chunk.chunk_index,
            "text": chunk.text,
            "similarity": float(sim)
        })

    similarities.sort(key=lambda x: x["similarity"], reverse=True)

    return {
        "query": payload.query,
        "results": similarities[:payload.top_k]
    }
