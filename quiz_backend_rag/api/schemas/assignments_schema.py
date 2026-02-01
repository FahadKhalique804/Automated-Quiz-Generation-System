from pydantic import BaseModel
from typing import Literal
from datetime import datetime

Status = Literal["assigned","completed","expired"]

class AssignmentBase(BaseModel):
    quiz_id: int
    assigned_by: int
    student_id: int | None = None
    due_at: datetime | None = None
    status: Status | None = "assigned"

class AssignmentCreate(AssignmentBase):
    pass

class AssignmentUpdate(BaseModel):
    status: Status | None = None
    due_at: datetime | None = None

class AssignmentOut(AssignmentBase):
    id: int
    assigned_at: datetime | None = None
    class Config:
        orm_mode = True
