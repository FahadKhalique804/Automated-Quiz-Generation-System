from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.assignments import Assignment
from api.schemas.assignments_schema import AssignmentCreate, AssignmentOut, AssignmentUpdate

router = APIRouter(prefix="/assignments", tags=["Assignments"])

@router.post("/", response_model=AssignmentOut)
def create_assignment(payload: AssignmentCreate, db: Session = Depends(get_db)):
    a = Assignment(quiz_id=payload.quiz_id, assigned_by=payload.assigned_by,
                   student_id=payload.student_id, due_at=payload.due_at, status=payload.status)
    db.add(a); db.commit(); db.refresh(a)
    return a

@router.get("/", response_model=list[AssignmentOut])
def list_assignments(skip: int = 0, limit: int = Query(100, le=200), db: Session = Depends(get_db)):
    return db.query(Assignment).offset(skip).limit(limit).all()

@router.get("/by-student/{student_id}", response_model=list[AssignmentOut])
def assignments_by_student(student_id: int, db: Session = Depends(get_db)):
    return db.query(Assignment).filter(Assignment.student_id==student_id).all()

@router.get("/by-quiz/{quiz_id}", response_model=list[AssignmentOut])
def assignments_by_quiz(quiz_id: int, db: Session = Depends(get_db)):
    return db.query(Assignment).filter(Assignment.quiz_id==quiz_id).all()

@router.put("/{assignment_id}", response_model=AssignmentOut)
def update_assignment(assignment_id: int, payload: AssignmentUpdate, db: Session = Depends(get_db)):
    a = db.query(Assignment).get(assignment_id)
    if not a:
        raise HTTPException(404, "Assignment not found")
    if payload.status is not None: a.status = payload.status
    if payload.due_at is not None: a.due_at = payload.due_at
    db.add(a); db.commit(); db.refresh(a)
    return a

@router.delete("/{assignment_id}")
def delete_assignment(assignment_id: int, db: Session = Depends(get_db)):
    a = db.query(Assignment).get(assignment_id)
    if not a:
        raise HTTPException(404, "Assignment not found")
    db.delete(a); db.commit()
    return {"detail":"deleted"}
