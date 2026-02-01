from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.enrollments import Enrollment
from api.schemas.enrollments_schema import EnrollmentCreate, EnrollmentOut

router = APIRouter(prefix="/enrollments", tags=["Enrollments"])

@router.post("/", response_model=EnrollmentOut)
def enroll_student(payload: EnrollmentCreate, db: Session = Depends(get_db)):
    exist = db.query(Enrollment).filter(Enrollment.student_id==payload.student_id, Enrollment.course_id==payload.course_id).first()
    if exist:
        raise HTTPException(400, "Already enrolled")
    e = Enrollment(student_id=payload.student_id, course_id=payload.course_id)
    db.add(e); db.commit(); db.refresh(e)
    return e

@router.get("/", response_model=list[EnrollmentOut])
def list_enrollments(db: Session = Depends(get_db)):
    return db.query(Enrollment).all()

@router.get("/by-student/{student_id}", response_model=list[EnrollmentOut])
def enrollments_by_student(student_id: int, db: Session = Depends(get_db)):
    return db.query(Enrollment).filter(Enrollment.student_id==student_id).all()

@router.get("/by-course/{course_id}", response_model=list[EnrollmentOut])
def enrollments_by_course(course_id: int, db: Session = Depends(get_db)):
    return db.query(Enrollment).filter(Enrollment.course_id==course_id).all()

@router.delete("/{enrollment_id}")
def delete_enrollment(enrollment_id: int, db: Session = Depends(get_db)):
    rec = db.query(Enrollment).get(enrollment_id)
    if not rec:
        raise HTTPException(404, "Enrollment not found")
    db.delete(rec); db.commit()
    return {"detail":"deleted"}
