from sqlalchemy import Column, Integer, Text, Enum, ForeignKey
from api.database import Base

class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    q_order = Column(Integer, nullable=False)
    question_text = Column(Text, nullable=False)
    option_a = Column(Text, nullable=False)
    option_b = Column(Text, nullable=False)
    option_c = Column(Text, nullable=False)
    option_d = Column(Text, nullable=False)
    correct_option = Column(Enum("A", "B", "C", "D"), nullable=False)
    difficulty = Column(Enum("Easy", "Medium", "Hard"), nullable=True)
    time_secs = Column(Integer, default=0)
    marks = Column(Integer, default=1)
