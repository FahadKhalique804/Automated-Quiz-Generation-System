from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.quiz_questions import QuizQuestion
from api.schemas.quiz_questions_schema import QuizQuestionCreate, QuizQuestionOut

router = APIRouter(prefix="/quiz-questions", tags=["QuizQuestions"])

@router.post("/", response_model=QuizQuestionOut)
def create_question(payload: QuizQuestionCreate, db: Session = Depends(get_db)):
    # ensure unique q_order for quiz
    existing = db.query(QuizQuestion).filter(QuizQuestion.quiz_id==payload.quiz_id, QuizQuestion.q_order==payload.q_order).first()
    if existing:
        raise HTTPException(400, "q_order already exists for this quiz")
    q = QuizQuestion(
        quiz_id=payload.quiz_id, q_order=payload.q_order, question_text=payload.question_text,
        option_a=payload.option_a, option_b=payload.option_b, option_c=payload.option_c, option_d=payload.option_d,
        correct_option=payload.correct_option, difficulty=payload.difficulty, time_secs=payload.time_secs, marks=payload.marks
    )
    db.add(q); db.commit(); db.refresh(q)
    return q

@router.get("/", response_model=list[QuizQuestionOut])
def list_questions(db: Session = Depends(get_db)):
    return db.query(QuizQuestion).all()

@router.get("/by-quiz/{quiz_id}", response_model=list[QuizQuestionOut])
def questions_by_quiz(quiz_id: int, db: Session = Depends(get_db)):
    return db.query(QuizQuestion).filter(QuizQuestion.quiz_id==quiz_id).order_by(QuizQuestion.q_order).all()

@router.get("/{question_id}", response_model=QuizQuestionOut)
def get_question(question_id: int, db: Session = Depends(get_db)):
    q = db.query(QuizQuestion).get(question_id)
    if not q:
        raise HTTPException(404, "Question not found")
    return q

@router.put("/{question_id}", response_model=QuizQuestionOut)
def update_question(question_id: int, payload: QuizQuestionCreate, db: Session = Depends(get_db)):
    q = db.query(QuizQuestion).get(question_id)
    if not q:
        raise HTTPException(404, "Question not found")
    # update fields
    q.q_order = payload.q_order
    q.question_text = payload.question_text
    q.option_a = payload.option_a
    q.option_b = payload.option_b
    q.option_c = payload.option_c
    q.option_d = payload.option_d
    q.correct_option = payload.correct_option
    q.difficulty = payload.difficulty
    q.time_secs = payload.time_secs
    q.marks = payload.marks
    db.add(q); db.commit(); db.refresh(q)
    return q

@router.delete("/{question_id}")
def delete_question(question_id: int, db: Session = Depends(get_db)):
    q = db.query(QuizQuestion).get(question_id)
    if not q:
        raise HTTPException(404, "Question not found")
    db.delete(q); db.commit()
    return {"detail":"deleted"}
