from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.question_library import QuestionLibrary
from api.models.quizzes import Quiz
from api.schemas.question_library_schema import QuestionLibraryOut, MarkPoorRequest

router = APIRouter(prefix="/question-library", tags=["QuestionLibrary"])

@router.get("/by-note/{note_id}", response_model=list[QuestionLibraryOut])
def get_library_questions(note_id: int, db: Session = Depends(get_db)):
    # Return all questions (Good and Poor) for transparency, or we could filter.
    # Requirement says "view previously generated question", implies all valid ones.
    # Teacher might want to see poor ones too to avoid them? 
    # Let's filter by 'good_question' by default? 
    # User said: "if teacher mark a question as a 'poor_question' then it will stored as poor_question... 
    # but not in 'quiz_questions' table."
    # AND "teacher can view previously generated questions...". 
    # Usually we only want to reuse good questions.
    return db.query(QuestionLibrary).filter(
        QuestionLibrary.lecture_note_id == note_id,
        QuestionLibrary.question_quality == 'good_question'
    ).all()

@router.post("/mark-poor")
def mark_question_poor(payload: MarkPoorRequest, db: Session = Depends(get_db)):
    # We need to find the question in the library.
    # We have quiz_id and question_text.
    # First find the quiz to get the lecture_note_id (since library is linked to note)
    quiz = db.query(Quiz).get(payload.quiz_id)
    if not quiz:
        raise HTTPException(404, "Quiz not found")
        
    # Find the question in the library
    # It should exist since we save everything to library on generation.
    # We match by text and note_id.
    q_lib = db.query(QuestionLibrary).filter(
        QuestionLibrary.lecture_note_id == quiz.lecture_notes_id,
        QuestionLibrary.question_text == payload.question_text
    ).first()
    
    if not q_lib:
        # Fallback: maybe it wasn't there? Create it as poor? 
        # Or just error? Let's error for now as it should be there.
        raise HTTPException(404, "Question not found in library")
        
    q_lib.question_quality = 'poor_question'
    db.commit()
    db.refresh(q_lib)
    return {"status": "marked as poor", "id": q_lib.id}
