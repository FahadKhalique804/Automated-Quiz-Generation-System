# api/schemas/lecture_notes_schema.py
from pydantic import BaseModel

class LectureNoteBase(BaseModel):
    course_id: int
    uploaded_by: int
    file_path: str
    original_name: str | None = None

class LectureNoteCreate(LectureNoteBase):
    pass

class LectureNoteOut(LectureNoteBase):
    id: int
    uploaded_at: str | None = None
    class Config:
        orm_mode = True
