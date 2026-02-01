from sqlalchemy import Column, Integer, Text, Enum, ForeignKey
from api.database import Base

class QuestionLibrary(Base):
    __tablename__ = "question_library"

    id = Column(Integer, primary_key=True, index=True)
    lecture_note_id = Column(Integer, ForeignKey("lecture_notes.id", ondelete="CASCADE"), nullable=False)
    question_text = Column(Text, nullable=False)
    option_a = Column(Text, nullable=False)
    option_b = Column(Text, nullable=False)
    option_c = Column(Text, nullable=False)
    option_d = Column(Text, nullable=False)
    correct_option = Column(Enum("A", "B", "C", "D"), nullable=False)
    difficulty = Column(Enum("Easy", "Medium", "Hard"), nullable=True)
    time_secs = Column(Integer, default=60)
    
    # New column for quality feedback
    question_quality = Column(Enum("good_question", "poor_question"), default="good_question")
