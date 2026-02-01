from pydantic import BaseModel

class QuizGenRequest(BaseModel):
    lecture_note_id: int
    title: str
    created_by: int
    course_id: int
    num_questions: int = 10
    top_k_context: int = 8
    difficulty: str = "mixed"

class MCQOut(BaseModel):
    question: str
    options: dict
    correct: str | None = None
    difficulty: str | None = None
    time_secs: int | None = None

class QuizGenResponse(BaseModel):
    quiz_id: int
    total_generated: int
    questions: list[MCQOut]

class QuizFinalizeRequest(BaseModel):
    lecture_note_id: int
    topic: str
    difficulty: str
    questions: list[MCQOut]

