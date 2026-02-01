from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.lecture_notes import LectureNote
from api.schemas.lecture_notes_schema import LectureNoteCreate, LectureNoteOut
from api.services import ingest_service
import shutil
import os
import uuid

router = APIRouter(prefix="/lecture-notes", tags=["LectureNotes"])

@router.post("/")
def create_note(
    course_id: int = Form(...),
    uploaded_by: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # 1. Setup paths
    upload_dir = "PDF"
    os.makedirs(upload_dir, exist_ok=True)
    
    # Generate unique filename to facilitate storage
    file_ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(upload_dir, unique_filename)
    
    # 2. Save file to disk
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save file: {e}")

    try:
        # 3. Create LectureNote Record
        note = LectureNote(
            course_id=course_id, 
            uploaded_by=uploaded_by,
            file_path=file_path, 
            original_name=file.filename
        )
        db.add(note)
        db.commit()
        db.refresh(note)

        # 4. Ingest: Text Extraction & Chunking & Embedding
        # Extract
        text = ingest_service.extract_text_from_pdf(file_path)
        
        # Process (Chunk + Embed + Save)
        chunks_count, embeddings_count = ingest_service.process_and_store_chunks(db, note.id, text)

        return {
            "id": note.id,
            "chunks_created": chunks_count,
            "embeddings_created": embeddings_count,
            "status": "processed"
        }

    except Exception as e:
        db.rollback()
        # Clean up file if DB failed (optional but good practice)
        if os.path.exists(file_path):
            os.remove(file_path)
        return {
            "status": "failed",
            "error": str(e),
            "chunks_created": 0
        }

@router.get("/", response_model=list[LectureNoteOut])
def list_notes(db: Session = Depends(get_db)):
    return db.query(LectureNote).all()

@router.get("/{note_id}", response_model=LectureNoteOut)
def get_note(note_id: int, db: Session = Depends(get_db)):
    n = db.query(LectureNote).get(note_id)
    if not n:
        raise HTTPException(404, "Note not found")
    return n

@router.get("/by-course/{course_id}", response_model=list[LectureNoteOut])
def notes_by_course(course_id: int, db: Session = Depends(get_db)):
    return db.query(LectureNote).filter(LectureNote.course_id==course_id).all()

@router.delete("/{note_id}")
def delete_note(note_id: int, db: Session = Depends(get_db)):
    n = db.query(LectureNote).get(note_id)
    if not n:
        raise HTTPException(404, "Note not found")
    db.delete(n); db.commit()
    return {"detail":"deleted"}
