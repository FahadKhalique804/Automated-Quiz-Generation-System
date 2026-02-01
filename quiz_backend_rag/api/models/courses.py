from sqlalchemy import Column, Integer, String, TIMESTAMP
from api.database import Base

class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, nullable=True)
    title = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP, nullable=True)