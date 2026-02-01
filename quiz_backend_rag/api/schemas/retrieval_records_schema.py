from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ----------------------------
# Base Schema
# ----------------------------
class RetrievalRecordBase(BaseModel):
    quiz_id: int
    chunk_id: int
    similarity_score: Optional[float] = None


# ----------------------------
# Schema for Creating
# ----------------------------
class RetrievalRecordCreate(RetrievalRecordBase):
    pass


# ----------------------------
# Schema Returning to Client
# ----------------------------
class RetrievalRecordResponse(RetrievalRecordBase):
    id: int
    used_at: datetime

    class Config:
        orm_mode = True
