from sqlalchemy import Column, Integer, Enum, TIMESTAMP, ForeignKey
from api.database import Base

class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    assigned_by = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=True)
    due_at = Column(TIMESTAMP, nullable=True)
    status = Column(Enum("assigned", "completed", "expired"), default="assigned")
    assigned_at = Column(TIMESTAMP, nullable=True)
