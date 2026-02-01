from sqlalchemy import Column, Integer, ForeignKey
from api.database import Base

class Teaches(Base):
    __tablename__ = "teaches"

    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), primary_key=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), primary_key=True)
