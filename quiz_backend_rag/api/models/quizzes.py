from sqlalchemy import Column, Integer, String, Enum, ForeignKey, TIMESTAMP, Boolean
from sqlalchemy.orm import relationship
from api.database import Base

class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    created_by = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    lecture_notes_id = Column(Integer, ForeignKey("lecture_notes.id", ondelete="SET NULL"), nullable=True)
    title = Column(String(255), nullable=False)
    total_questions = Column(Integer, default=0)
    avg_difficulty = Column(Enum("Easy", "Medium", "Hard"), nullable=True)
    total_time_mins = Column(Integer, default=0)
    total_marks = Column(Integer, default=0)
    total_marks = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, nullable=True)
    is_published = Column(Boolean, default=False)

    retrieval_records = relationship(
    "RetrievalRecord",
    back_populates="quiz",
    cascade="all, delete"
)
