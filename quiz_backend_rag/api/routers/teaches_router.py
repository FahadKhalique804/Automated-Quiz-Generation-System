from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.teaches import Teaches
from api.schemas.teaches_schema import TeachesCreate, TeachesOut

router = APIRouter(prefix="/teaches", tags=["Teaches"])

@router.post("/", response_model=TeachesOut)
def assign_teacher(payload: TeachesCreate, db: Session = Depends(get_db)):
    existing = db.query(Teaches).filter(Teaches.teacher_id==payload.teacher_id, Teaches.course_id==payload.course_id).first()
    if existing:
        raise HTTPException(400, "Mapping already exists")
    t = Teaches(teacher_id=payload.teacher_id, course_id=payload.course_id)
    db.add(t); db.commit()
    return payload

@router.get("/", response_model=list[TeachesOut])
def list_teaches(db: Session = Depends(get_db)):
    return db.query(Teaches).all()

@router.delete("/", response_model=dict)
def remove_teach(teacher_id: int, course_id: int, db: Session = Depends(get_db)):
    rec = db.query(Teaches).filter(Teaches.teacher_id==teacher_id, Teaches.course_id==course_id).first()
    if not rec:
        raise HTTPException(404, "Not found")
    db.delete(rec); db.commit()
    return {"detail":"deleted"}
