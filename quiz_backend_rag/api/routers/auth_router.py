from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from api.database import get_db
from api.schemas.auth_schema import LoginRequest, LoginResponse
from api.models.teachers import Teacher
from api.models.students import Student

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    # 1. Check Hardcoded Admin
    if payload.email == "admin@biit.edu.com" and payload.password == "admin123":
        return LoginResponse(
            id=1,
            name="Admin User",
            email=payload.email,
            role="admin",
            token="admin-token" # Mock token
        )

    # 2. Check Teacher
    teacher = db.query(Teacher).filter(Teacher.email == payload.email).first()
    if teacher:
        # verifying password (plaintext for now as per current codebase state)
        if teacher.password_hash == payload.password:
             return LoginResponse(
                id=teacher.id,
                name=teacher.name,
                email=teacher.email,
                role="teacher",
                token=f"teacher-token-{teacher.id}"
            )
        else:
            # If email matches but password wrong, return 401
             raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    # 3. Check Student
    student = db.query(Student).filter(Student.email == payload.email).first()
    if student:
        # verifying password (plaintext for now)
        if student.password_hash == payload.password:
             return LoginResponse(
                id=student.id,
                name=student.name,
                email=student.email,
                role="student",
                token=f"student-token-{student.id}"
            )
        else:
             raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    
    # 4. If no match
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
