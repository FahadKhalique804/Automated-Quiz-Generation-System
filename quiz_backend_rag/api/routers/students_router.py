from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.students import Student
from api.schemas.students_schema import StudentCreate, StudentOut, StudentUpdate

router = APIRouter(prefix="/students", tags=["Students"])

@router.post("/", response_model=StudentOut)
def create_student(payload: StudentCreate, db: Session = Depends(get_db)):
    existing = db.query(Student).filter(Student.email == payload.email).first()
    if existing:
        raise HTTPException(400, "Email already registered")
    s = Student(name=payload.name, email=payload.email, password_hash=payload.password,
                reg_no=payload.reg_no, semester=payload.semester)
    db.add(s); db.commit(); db.refresh(s)
    return s

@router.get("/", response_model=list[StudentOut])
def list_students(db: Session = Depends(get_db)):
    return db.query(Student).all()

@router.get("/{student_id}", response_model=StudentOut)
def get_student(student_id: int, db: Session = Depends(get_db)):
    s = db.query(Student).get(student_id)
    if not s:
        raise HTTPException(404, "Student not found")
    return s

@router.put("/{student_id}", response_model=StudentOut)
def update_student(student_id: int, payload: StudentUpdate, db: Session = Depends(get_db)):
    s = db.query(Student).get(student_id)
    if not s:
        raise HTTPException(404, "Student not found")
    if payload.name: s.name = payload.name
    if payload.email: s.email = payload.email
    if payload.reg_no is not None: s.reg_no = payload.reg_no
    if payload.semester is not None: s.semester = payload.semester
    if payload.password: s.password_hash = payload.password
    db.add(s); db.commit(); db.refresh(s)
    return s

@router.delete("/{student_id}")
def delete_student(student_id: int, db: Session = Depends(get_db)):
    s = db.query(Student).get(student_id)
    if not s:
        raise HTTPException(404, "Student not found")
    db.delete(s); db.commit()
    return {"detail":"deleted"}
