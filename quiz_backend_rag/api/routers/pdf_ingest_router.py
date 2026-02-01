# from fastapi import APIRouter, Depends, HTTPException
# from sqlalchemy.orm import Session
# from api.database import get_db
# from api.models.lecture_notes import LectureNote
# from api.models.chunks import Chunk
# from pypdf import PdfReader
# import os
#
# router = APIRouter(prefix="/pdf", tags=["PDF Ingestion"])
#
#
# def split_into_chunks(text: str, max_length: int = 1000):
#     words = text.split()
#     chunks = []
#     current = []
#
#     for w in words:
#         if sum(len(x) + 1 for x in current) + len(w) > max_length:
#             chunks.append(" ".join(current))
#             current = []
#         current.append(w)
#
#     if current:
#         chunks.append(" ".join(current))
#
#     return chunks
#
#
# @router.post("/process/{lecture_note_id}")
# def process_pdf(lecture_note_id: int, db: Session = Depends(get_db)):
#     # 1️⃣ Fetch lecture note record
#     note = db.query(LectureNote).get(lecture_note_id)
#     if not note:
#         raise HTTPException(404, "Lecture note not found")
#
#     if not os.path.exists(note.file_path):
#         raise HTTPException(400, "PDF file does not exist on server")
#
#     # 2️⃣ Open and extract text
#     try:
#         pdf = PdfReader(note.file_path)
#         extracted_text = ""
#
#         for page in pdf.pages:
#             extracted_text += page.extract_text() + "\n"
#
#         if not extracted_text.strip():
#             raise HTTPException(400, "No extractable text in PDF")
#
#         # 3️⃣ Split text
#         text_chunks = split_into_chunks(extracted_text)
#
#         # 4️⃣ Store chunks in DB
#         for idx, chunk_text in enumerate(text_chunks):
#             chunk = Chunk(
#                 lecture_notes_id=lecture_note_id,
#                 chunk_index=idx,
#                 text=chunk_text,
#                 keywords=None,
#                 embedding=None,
#             )
#             db.add(chunk)
#
#         db.commit()
#
#         return {
#             "lecture_note_id": lecture_note_id,
#             "total_chunks": len(text_chunks),
#             "message": "PDF processed successfully.",
#         }
#
#     except Exception as e:
#         raise HTTPException(500, f"PDF processing error: {e}")

##### UPDATED CODE FOR CLEANING BEFORE CHUNKING ######

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from api.database import get_db
from api.models.lecture_notes import LectureNote
from api.models.chunks import Chunk
from pypdf import PdfReader
import re
import os

router = APIRouter(prefix="/pdf", tags=["PDF Ingestion"])


# -----------------------------------------------------
#  CLEANING UTILITIES
# -----------------------------------------------------

def clean_text(raw: str) -> str:
    """Clean PDF extracted text before chunking."""

    text = raw

    # 1️⃣ Remove repeated lecture headers/footers (your PDF pattern)
    header_pattern = r"Programming Fundamentals.*?0332-7661819"
    text = re.sub(header_pattern, "", text, flags=re.DOTALL)

    # 2️⃣ Remove email & WhatsApp patterns
    text = re.sub(r"\S+@\S+", "", text)  # remove emails
    text = re.sub(r"\b\d{11}\b", "", text)  # phone numbers like 03005137383

    # 3️⃣ Remove URLs
    text = re.sub(r"http\S+|www\.\S+", "", text)

    # 4️⃣ Remove page numbers (standalone digits)
    text = re.sub(r"\n?\s*\b\d{1,3}\b\s*\n", "\n", text)

    # 5️⃣ Fix broken words (optional minimal rule)
    text = text.replace("  ", " ")
    text = re.sub(r"\s+", " ", text)

    # 6️⃣ Normalize whitespace & clean edges
    text = text.strip()

    return text


# -----------------------------------------------------
#  CHUNKING LOGIC
# -----------------------------------------------------

def split_into_chunks(text: str, max_length: int = 1000):
    """Split cleaned text into chunks of approx max_length chars."""
    words = text.split()
    chunks = []
    current = []

    for w in words:
        if sum(len(x) + 1 for x in current) + len(w) > max_length:
            chunks.append(" ".join(current))
            current = []
        current.append(w)

    if current:
        chunks.append(" ".join(current))

    return chunks


# -----------------------------------------------------
#  MAIN ENDPOINT: PROCESS PDF
# -----------------------------------------------------

@router.post("/process/{lecture_note_id}")
def process_pdf(lecture_note_id: int, db: Session = Depends(get_db)):
    # 1️⃣ Fetch lecture note record
    note = db.query(LectureNote).get(lecture_note_id)
    if not note:
        raise HTTPException(404, "Lecture note not found")

    if not os.path.exists(note.file_path):
        raise HTTPException(400, "PDF file does not exist on server")

    # 2️⃣ Read PDF
    try:
        pdf = PdfReader(note.file_path)
        extracted_text = ""

        for page in pdf.pages:
            extracted_text += page.extract_text() + "\n"

        if not extracted_text.strip():
            raise HTTPException(400, "No extractable text in PDF")

        # 3️⃣ Clean the text BEFORE chunking
        cleaned_text = clean_text(extracted_text)

        if not cleaned_text.strip():
            raise HTTPException(400, "Text cleaning removed too much content")

        # 4️⃣ Chunk the cleaned text
        text_chunks = split_into_chunks(cleaned_text)

        # 5️⃣ Save chunks into DB
        for idx, chunk_text in enumerate(text_chunks):
            chunk = Chunk(
                lecture_notes_id=lecture_note_id,
                chunk_index=idx,
                text=chunk_text,
                keywords=None,
                embedding=None,
            )
            db.add(chunk)

        db.commit()

        return {
            "lecture_note_id": lecture_note_id,
            "raw_text_length": len(extracted_text),
            "cleaned_text_length": len(cleaned_text),
            "total_chunks": len(text_chunks),
            "message": "PDF processed, cleaned, chunked, saved.",
        }

    except Exception as e:
        raise HTTPException(500, f"PDF processing error: {e}")
