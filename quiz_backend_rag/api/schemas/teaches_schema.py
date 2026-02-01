from pydantic import BaseModel

class TeachesBase(BaseModel):
    teacher_id: int
    course_id: int

class TeachesCreate(TeachesBase):
    pass

class TeachesOut(TeachesBase):
    class Config:
        orm_mode = True
