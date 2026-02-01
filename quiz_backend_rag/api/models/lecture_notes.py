from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey
from sqlalchemy.orm import relationship
from api.database import Base

class LectureNote(Base):
    __tablename__ = "lecture_notes"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    uploaded_by = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    file_path = Column(String(500), nullable=False)
    original_name = Column(String(255), nullable=True)
    uploaded_at = Column(TIMESTAMP, nullable=True)
    chunks = relationship("Chunk", back_populates="lecture_notes")