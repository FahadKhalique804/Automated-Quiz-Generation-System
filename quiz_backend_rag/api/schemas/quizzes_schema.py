from pydantic import BaseModel
from typing import Literal
from datetime import datetime

Difficulty = Literal["Easy","Medium","Hard"]

class QuizBase(BaseModel):
    course_id: int
    created_by: int
    lecture_notes_id: int | None = None
    title: str

class QuizCreate(QuizBase):
    total_questions: int | None = 0
    avg_difficulty: Difficulty | None = None
    total_time_mins: int | None = 0
    total_marks: int | None = 0

class QuizUpdate(BaseModel):
    title: str | None = None
    total_questions: int | None = None
    avg_difficulty: Difficulty | None = None
    total_time_mins: int | None = None
    total_marks: int | None = None

class QuizOut(QuizBase):
    id: int
    total_questions: int
    avg_difficulty: Difficulty | None
    total_time_mins: int
    total_marks: int
    created_at: datetime | None = None
    is_published: bool | None = False
    class Config:
        orm_mode = True

class QuizGenerateRequest(BaseModel):
    lecture_note_id: int
    topic: str
    num_questions: int = 5
    difficulty: str = "Medium" # Kept for backward compatibility or default
    difficulty_dict: dict[str, int] | None = None # e.g. {"Easy": 3, "Hard": 5}
    selected_library_question_ids: list[int] = []
