from pydantic import BaseModel
from typing import Any
from datetime import datetime

class AttemptBase(BaseModel):
    assignment_id: int
    quiz_id: int
    student_id: int
    submitted_answers: Any  # JSON object
    total_correct: int | None = 0
    percentage: float | None = None
    teacher_feedback: str | None = None

class AttemptCreate(AttemptBase):
    pass

class AttemptUpdate(BaseModel):
    percentage: float | None = None
    total_correct: int | None = None
    teacher_feedback: str | None = None

class AttemptOut(AttemptBase):
    id: int
    submitted_at: datetime | None = None
    class Config:
        orm_mode = True
