from pydantic import BaseModel
from datetime import datetime

class CourseBase(BaseModel):
    code: str | None = None
    title: str

class CourseCreate(CourseBase):
    pass

class CourseUpdate(BaseModel):
    code: str | None = None
    title: str | None = None

class CourseOut(CourseBase):
    id: int
    created_at: datetime | None = None
    class Config:
        orm_mode = True
