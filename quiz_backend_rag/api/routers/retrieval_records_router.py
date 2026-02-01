from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.retrieval_records import RetrievalRecord
from api.schemas.retrieval_records_schema import (
RetrievalRecordCreate,
RetrievalRecordResponse,
)
router = APIRouter(prefix="/retrieval-records", tags=["Retrieval Records"])

# -------------------------------

# Create a new retrieval record

# -------------------------------

@router.post("/", response_model=RetrievalRecordResponse)
def create_retrieval_record(payload: RetrievalRecordCreate, db: Session = Depends(get_db)):
    new_record = RetrievalRecord(
        quiz_id=payload.quiz_id,
        chunk_id=payload.chunk_id,
        similarity_score=payload.similarity_score,
    )
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    return new_record

# -------------------------------

# Get all retrieval records for a quiz

# -------------------------------

@router.get("/quiz/{quiz_id}", response_model=list[RetrievalRecordResponse])
def get_records_for_quiz(quiz_id: int, db: Session = Depends(get_db)):
    return (
        db.query(RetrievalRecord)
        .filter(RetrievalRecord.quiz_id == quiz_id)
        .order_by(RetrievalRecord.similarity_score.desc())
        .all()
    )

# -------------------------------

# Delete all records for a quiz

# -------------------------------

@router.delete("/quiz/{quiz_id}")
def delete_records_for_quiz(quiz_id: int, db: Session = Depends(get_db)):
    db.query(RetrievalRecord).filter(
        RetrievalRecord.quiz_id == quiz_id
    ).delete()
    db.commit()
    return {"detail": "All retrieval records deleted for quiz"}
