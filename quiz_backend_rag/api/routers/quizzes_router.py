from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.quizzes import Quiz
from api.schemas.quizzes_schema import QuizCreate, QuizOut, QuizUpdate, QuizGenerateRequest
from api.schemas.quiz_gen_schema import QuizFinalizeRequest, MCQOut
from api.services.quiz_generation_service import generate_quiz, generate_questions_preview, finalize_quiz

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

@router.post("/", response_model=QuizOut)
def create_quiz(payload: QuizCreate, db: Session = Depends(get_db)):
    q = Quiz(course_id=payload.course_id, created_by=payload.created_by,
             lecture_notes_id=payload.lecture_notes_id, title=payload.title,
             total_questions=payload.total_questions or 0,
             avg_difficulty=payload.avg_difficulty,
             total_time_mins=payload.total_time_mins or 0,
             total_marks=payload.total_marks or 0)
    db.add(q); db.commit(); db.refresh(q)
    return q

@router.post("/generate")
async def generate_quiz_endpoint(
    payload: QuizGenerateRequest,
    db: Session = Depends(get_db)
):
    """
    Unified Endpoint:
    - Vector Search for context
    - Generate MCQs
    - Save Quiz & Questions to DB
    """
    result = await generate_quiz(
        db=db,
        lecture_note_id=payload.lecture_note_id,
        topic=payload.topic,
        difficulty=payload.difficulty,
        num_questions=payload.num_questions,
        difficulty_dict=payload.difficulty_dict,
        selected_library_question_ids=payload.selected_library_question_ids
    )
    return result

@router.post("/generate-preview", response_model=list[MCQOut])
async def generate_quiz_preview_endpoint(
    payload: QuizGenerateRequest,
    db: Session = Depends(get_db)
):
    """
    Generates questions for preview (no saving).
    """
    result = await generate_questions_preview(
        db=db,
        lecture_note_id=payload.lecture_note_id,
        topic=payload.topic,
        difficulty=payload.difficulty,
        num_questions=payload.num_questions,
        difficulty_dict=payload.difficulty_dict,
        selected_library_question_ids=payload.selected_library_question_ids
    )
    return result

@router.post("/finalize")
def finalize_quiz_endpoint(
    payload: QuizFinalizeRequest,
    db: Session = Depends(get_db)
):
    """
    Saves the finalized list of questions as a quiz.
    """
    # Convert Pydantic models to dicts for the service
    questions_dicts = [
        {
            "question": q.question,
            "options": q.options,
            "correct": q.correct,
            "difficulty": q.difficulty,
            "time_secs": q.time_secs
        }
        for q in payload.questions
    ]
    
    return finalize_quiz(
        db=db,
        lecture_note_id=payload.lecture_note_id,
        topic=payload.topic,
        difficulty=payload.difficulty,
        questions=questions_dicts
    )

@router.get("/", response_model=list[QuizOut])
def list_quizzes(skip: int = 0, limit: int = Query(100, le=100), db: Session = Depends(get_db)):
    return db.query(Quiz).offset(skip).limit(limit).all()

@router.get("/{quiz_id}", response_model=QuizOut)
def get_quiz(quiz_id: int, db: Session = Depends(get_db)):
    q = db.query(Quiz).get(quiz_id)
    if not q:
        raise HTTPException(404, "Quiz not found")
    return q

@router.get("/by-course/{course_id}", response_model=list[QuizOut])
def quizzes_by_course(course_id: int, db: Session = Depends(get_db)):
    return db.query(Quiz).filter(Quiz.course_id==course_id).all()

@router.get("/by-teacher/{teacher_id}", response_model=list[QuizOut])
def quizzes_by_teacher(teacher_id: int, db: Session = Depends(get_db)):
    return db.query(Quiz).filter(Quiz.created_by==teacher_id).all()

@router.put("/{quiz_id}", response_model=QuizOut)
def update_quiz(quiz_id: int, payload: QuizUpdate, db: Session = Depends(get_db)):
    q = db.query(Quiz).get(quiz_id)
    if not q:
        raise HTTPException(404, "Quiz not found")
    if payload.title is not None: q.title = payload.title
    if payload.total_questions is not None: q.total_questions = payload.total_questions
    if payload.avg_difficulty is not None: q.avg_difficulty = payload.avg_difficulty
    if payload.total_time_mins is not None: q.total_time_mins = payload.total_time_mins
    if payload.total_marks is not None: q.total_marks = payload.total_marks
    db.add(q); db.commit(); db.refresh(q)
    db.add(q); db.commit(); db.refresh(q)
    return q

@router.put("/{quiz_id}/publish", response_model=QuizOut)
def publish_quiz(quiz_id: int, db: Session = Depends(get_db)):
    q = db.query(Quiz).get(quiz_id)
    if not q:
        raise HTTPException(404, "Quiz not found")
    q.is_published = True
    db.add(q); db.commit(); db.refresh(q)
    return q

@router.delete("/{quiz_id}")
def delete_quiz(quiz_id: int, db: Session = Depends(get_db)):
    q = db.query(Quiz).get(quiz_id)
    if not q:
        raise HTTPException(404, "Quiz not found")
    db.delete(q); db.commit()
    return {"detail":"deleted"}
