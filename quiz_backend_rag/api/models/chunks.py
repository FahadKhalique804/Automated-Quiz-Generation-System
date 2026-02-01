

from sqlalchemy import Column, Integer, ForeignKey, Text, JSON, LargeBinary
from sqlalchemy.orm import relationship
from api.database import Base


class Chunk(Base):
    __tablename__ = "chunks"

    id = Column(Integer, primary_key=True, index=True)

    # FK → lecture_notes
    lecture_notes_id = Column(
        Integer,
        ForeignKey("lecture_notes.id", ondelete="CASCADE"),
        nullable=False
    )

    # Chunk ordering
    chunk_index = Column(Integer, default=0)

    # Raw extracted text
    text = Column(Text, nullable=False)

    # Optional extracted keywords
    keywords = Column(JSON, nullable=True)

    # Vector embedding (MySQL LONGBLOB)
    embedding = Column(LargeBinary, nullable=True)

    # Correct relationship → LectureNote
    lecture_notes = relationship("LectureNote", back_populates="chunks")

    # Correct relationship → RetrievalRecord
    retrieval_records = relationship("RetrievalRecord", back_populates="chunk")
