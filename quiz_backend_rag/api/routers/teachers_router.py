from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.teachers import Teacher
from api.schemas.teachers_schema import TeacherCreate, TeacherOut, TeacherUpdate

router = APIRouter(prefix="/teachers", tags=["Teachers"])

@router.post("/", response_model=TeacherOut)
def create_teacher(payload: TeacherCreate, db: Session = Depends(get_db)):
    # TODO: hash password in production
    existing = db.query(Teacher).filter(Teacher.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    t = Teacher(name=payload.name, email=payload.email, password_hash=payload.password)
    db.add(t); db.commit(); db.refresh(t)
    return t

@router.get("/", response_model=list[TeacherOut])
def list_teachers(db: Session = Depends(get_db)):
    return db.query(Teacher).all()

@router.get("/{teacher_id}", response_model=TeacherOut)
def get_teacher(teacher_id: int, db: Session = Depends(get_db)):
    t = db.query(Teacher).get(teacher_id)
    if not t:
        raise HTTPException(404, "Teacher not found")
    return t

@router.put("/{teacher_id}", response_model=TeacherOut)
def update_teacher(teacher_id: int, payload: TeacherUpdate, db: Session = Depends(get_db)):
    t = db.query(Teacher).get(teacher_id)
    if not t:
        raise HTTPException(404, "Teacher not found")
    if payload.name: t.name = payload.name
    if payload.email: t.email = payload.email
    if payload.password: t.password_hash = payload.password
    db.add(t); db.commit(); db.refresh(t)
    return t

@router.delete("/{teacher_id}")
def delete_teacher(teacher_id: int, db: Session = Depends(get_db)):
    t = db.query(Teacher).get(teacher_id)
    if not t:
        raise HTTPException(404, "Teacher not found")
    db.delete(t); db.commit()
    return {"detail":"deleted"}
