from pydantic import BaseModel
from typing import Literal

Difficulty = Literal["Easy","Medium","Hard"]
Quality = Literal["good_question", "poor_question"]

class QuestionLibraryBase(BaseModel):
    lecture_note_id: int
    question_text: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: Literal["A","B","C","D"]
    difficulty: Difficulty | None = None
    time_secs: int | None = 60
    question_quality: Quality = "good_question"

class QuestionLibraryCreate(QuestionLibraryBase):
    pass

class QuestionLibraryOut(QuestionLibraryBase):
    id: int
    class Config:
        orm_mode = True

class MarkPoorRequest(BaseModel):
    quiz_id: int
    question_text: str
