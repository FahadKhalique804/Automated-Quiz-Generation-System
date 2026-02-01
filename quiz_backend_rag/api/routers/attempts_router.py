from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.attempts import Attempt
from api.models.assignments import Assignment
from api.models.quizzes import Quiz
from api.schemas.attempts_schema import AttemptCreate, AttemptOut, AttemptUpdate

router = APIRouter(prefix="/attempts", tags=["Attempts"])

@router.post("/", response_model=AttemptOut)
def create_attempt(payload: AttemptCreate, db: Session = Depends(get_db)):
    a = Attempt(**payload.dict())
    a.submitted_at = datetime.now()
    db.add(a)
    db.commit()
    db.refresh(a)
    return a

@router.get("/", response_model=list[AttemptOut])
def list_attempts(db: Session = Depends(get_db)):
    return db.query(Attempt).all()

@router.get("/by-student/{student_id}", response_model=list[AttemptOut])
def attempts_by_student(student_id: int, db: Session = Depends(get_db)):
    return db.query(Attempt).filter(Attempt.student_id==student_id).all()

@router.get("/by-assignment/{assignment_id}", response_model=list[AttemptOut])
def attempts_by_assignment(assignment_id: int, db: Session = Depends(get_db)):
    return db.query(Attempt).filter(Attempt.assignment_id==assignment_id).all()

@router.get("/by-quiz/{quiz_id}", response_model=list[AttemptOut])
def attempts_by_quiz(quiz_id: int, db: Session = Depends(get_db)):
    return db.query(Attempt).filter(Attempt.quiz_id==quiz_id).all()

@router.get("/{attempt_id}", response_model=AttemptOut)
def get_attempt(attempt_id: int, db: Session = Depends(get_db)):
    a = db.query(Attempt).get(attempt_id)
    if not a:
        raise HTTPException(404, "Attempt not found")
    return a

@router.put("/{attempt_id}", response_model=AttemptOut)
def update_attempt(attempt_id: int, payload: AttemptUpdate, db: Session = Depends(get_db)):
    a = db.query(Attempt).get(attempt_id)
    if not a:
        raise HTTPException(404, "Attempt not found")
    
    if payload.percentage is not None:
        a.percentage = payload.percentage
    if payload.total_correct is not None:
        a.total_correct = payload.total_correct
    if payload.teacher_feedback is not None:
        a.teacher_feedback = payload.teacher_feedback

    db.add(a); db.commit(); db.refresh(a)
    return a

@router.delete("/{attempt_id}")
def delete_attempt(attempt_id: int, db: Session = Depends(get_db)):
    a = db.query(Attempt).get(attempt_id)
    if not a:
        raise HTTPException(404, "Attempt not found")
    db.delete(a); db.commit()
    return {"detail":"deleted"}
