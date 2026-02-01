from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.courses import Course
from api.schemas.courses_schema import CourseCreate, CourseOut, CourseUpdate

router = APIRouter(prefix="/courses", tags=["Courses"])

@router.post("/", response_model=CourseOut)
def create_course(payload: CourseCreate, db: Session = Depends(get_db)):
    if payload.code:
        existing = db.query(Course).filter(Course.code == payload.code).first()
        if existing:
            raise HTTPException(400, "Course code already exists")
    c = Course(code=payload.code, title=payload.title)
    db.add(c); db.commit(); db.refresh(c)
    return c

@router.get("/", response_model=list[CourseOut])
def list_courses(skip: int = 0, limit: int = Query(100, le=100), db: Session = Depends(get_db)):
    return db.query(Course).offset(skip).limit(limit).all()

@router.get("/{course_id}", response_model=CourseOut)
def get_course(course_id: int, db: Session = Depends(get_db)):
    c = db.query(Course).get(course_id)
    if not c:
        raise HTTPException(404, "Course not found")
    return c

@router.put("/{course_id}", response_model=CourseOut)
def update_course(course_id: int, payload: CourseUpdate, db: Session = Depends(get_db)):
    c = db.query(Course).get(course_id)
    if not c:
        raise HTTPException(404, "Course not found")
    if payload.code is not None: c.code = payload.code
    if payload.title is not None: c.title = payload.title
    db.add(c); db.commit(); db.refresh(c)
    return c

@router.delete("/{course_id}")
def delete_course(course_id: int, db: Session = Depends(get_db)):
    c = db.query(Course).get(course_id)
    if not c:
        raise HTTPException(404, "Course not found")
    db.delete(c); db.commit()
    return {"detail":"deleted"}
