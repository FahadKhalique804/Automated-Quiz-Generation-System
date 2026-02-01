from sqlalchemy import (
    Column, Integer, ForeignKey, DECIMAL, TIMESTAMP, func
)
from sqlalchemy.orm import relationship
from api.database import Base


class RetrievalRecord(Base):
    __tablename__ = "retrieval_records"

    id = Column(Integer, primary_key=True, index=True)

    quiz_id = Column(
        Integer,
        ForeignKey("quizzes.id", ondelete="CASCADE"),
        nullable=False
    )

    chunk_id = Column(
        Integer,
        ForeignKey("chunks.id", ondelete="CASCADE"),
        nullable=False
    )

    similarity_score = Column(DECIMAL(5, 4), default=None)

    used_at = Column(
        TIMESTAMP,
        server_default=func.current_timestamp()
    )

    # Relationships
    quiz = relationship("Quiz", back_populates="retrieval_records")
    chunk = relationship("Chunk", back_populates="retrieval_records")
