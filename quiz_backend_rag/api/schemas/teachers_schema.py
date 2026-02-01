from pydantic import BaseModel, EmailStr

class TeacherBase(BaseModel):
    name: str
    email: EmailStr

class TeacherCreate(TeacherBase):
    password: str  # plain password input (hash on server)

class TeacherUpdate(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
    password: str | None = None

class TeacherOut(TeacherBase):
    id: int
    class Config:
        orm_mode = True