from pydantic import BaseModel, EmailStr

class StudentBase(BaseModel):
    name: str
    email: EmailStr
    reg_no: str | None = None
    semester: str | None = None

class StudentCreate(StudentBase):
    password: str

class StudentUpdate(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
    reg_no: str | None = None
    semester: str | None = None
    password: str | None = None

class StudentOut(StudentBase):
    id: int
    class Config:
        orm_mode = True
