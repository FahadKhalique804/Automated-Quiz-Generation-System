from sqlalchemy import Column, Integer, String
from api.database import Base

class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    email = Column(String(200), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    reg_no = Column(String(100), nullable=True)
    semester = Column(String(50), nullable=True)