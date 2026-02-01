from pydantic import BaseModel
from typing import Literal

Difficulty = Literal["Easy","Medium","Hard"]
Option = str

class QuizQuestionBase(BaseModel):
    quiz_id: int
    q_order: int
    question_text: str
    option_a: Option
    option_b: Option
    option_c: Option
    option_d: Option
    correct_option: Literal["A","B","C","D"]
    difficulty: Difficulty | None = None
    time_secs: int | None = 0
    marks: int | None = 1

class QuizQuestionCreate(QuizQuestionBase):
    pass

class QuizQuestionOut(QuizQuestionBase):
    id: int
    class Config:
        orm_mode = True
