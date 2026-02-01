from sqlalchemy import Column, Integer, JSON, DECIMAL, TIMESTAMP, ForeignKey, Text
from api.database import Base

class Attempt(Base):
    __tablename__ = "attempts"

    id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(Integer, ForeignKey("assignments.id", ondelete="CASCADE"), nullable=False)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    submitted_answers = Column(JSON, nullable=False)
    total_correct = Column(Integer, default=0)
    percentage = Column(DECIMAL(5, 2), nullable=True)
    submitted_at = Column(TIMESTAMP, nullable=True)
    teacher_feedback = Column(Text, nullable=True)
