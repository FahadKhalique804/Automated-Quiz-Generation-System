# from pydantic import BaseModel
# from typing import Optional, List


# # ----------------------------
# # Base Schema (Shared Fields)
# # ----------------------------
# class ChunkBase(BaseModel):
#     lecture_notes_id: int
#     chunk_index: int
#     text: str
#     keywords: Optional[dict] = None


# # ----------------------------
# # Schema for Creating a Chunk
# # ----------------------------
# class ChunkCreate(ChunkBase):
#     embedding: Optional[bytes] = None  # Stored as LONGBLOB


# # ----------------------------
# # Schema Returned to API
# # ----------------------------
# class ChunkResponse(ChunkBase):
#     id: int

#     class Config:
#         orm_mode = True
