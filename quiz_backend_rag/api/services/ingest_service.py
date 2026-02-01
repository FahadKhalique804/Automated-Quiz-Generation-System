
from pypdf import PdfReader
from sqlalchemy.orm import Session
from api.models.chunks import Chunk
from api.utils.embedding_utils import generate_embedding
import re
import os

def extract_text_from_pdf(file_path: str) -> str:
    """Read PDF file and extract text."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    reader = PdfReader(file_path)
    text = ""
    for page in reader.pages:
        text += page.extract_text() + "\n"
    
    return text

def clean_text(raw: str) -> str:
    """Clean PDF extracted text before chunking."""
    text = raw

    # 1. Remove repeated lecture headers/footers (regex adapted from old router)
    header_pattern = r"Programming Fundamentals.*?0332-7661819"
    text = re.sub(header_pattern, "", text, flags=re.DOTALL)

    # 2. Remove email & WhatsApp patterns
    text = re.sub(r"\S+@\S+", "", text)  # remove emails
    text = re.sub(r"\b\d{11}\b", "", text)  # phone numbers like 03005137383

    # 3. Remove URLs
    text = re.sub(r"http\S+|www\.\S+", "", text)

    # 4. Remove page numbers (standalone digits)
    text = re.sub(r"\n?\s*\b\d{1,3}\b\s*\n", "\n", text)

    # 5. Fix broken words & normalize whitespace
    text = text.replace("  ", " ")
    text = re.sub(r"\s+", " ", text) # collapse multiple spaces/newlines to single space

    return text.strip()

def split_into_chunks(text: str, chunk_size: int = 1000, overlap: int = 150) -> list[str]:
    """
    Split text into character-based chunks with overlap.
    TARGET: ~800-1200 chars. Default 1000.
    OVERLAP: ~100-150 chars. Default 150.
    """
    if not text:
        return []
    
    chunks = []
    start = 0
    text_len = len(text)

    while start < text_len:
        end = start + chunk_size
        
        # If we are near the end, just take the rest
        if end >= text_len:
            chunks.append(text[start:])
            break
        
        # Try to find a space or punctuation to break on near the end
        # We look back from 'end' to find a suitable break point
        # to avoid splitting words in half if possible.
        # Look back up to 'overlap' distance? Or just a small window?
        # Let's just hard slice for now if we want strict char limits, 
        # but better to break on space.
        
        # Simple algorithm: slice exactly, but maybe backup to last space?
        # Let's try to back up to the last space within the last 50 chars of the chunk
        # to avoid cutting words.
        
        slice_candidate = text[start:end]
        last_space = slice_candidate.rfind(' ')
        
        # If valid space found in the last 10% of the chunk, break there
        if last_space != -1 and last_space > (chunk_size * 0.9):
            end = start + last_space
        
        chunks.append(text[start:end])
        
        # Move start forward, respecting overlap
        start = end - overlap
        
        # Helper to avoid infinite loop if overlap >= chunk_size (shouldn't happen with defaults)
        if start >= end:
            start = end

    return chunks

def process_and_store_chunks(db: Session, lecture_note_id: int, text: str):
    """
    Splits text, generates embeddings, and stores Chunks in DB.
    """
    # 1. Clean
    cleaned_text = clean_text(text)
    
    # 2. Chunk
    chunks_text = split_into_chunks(cleaned_text)
    
    if not chunks_text:
        return 0, 0

    embeddings_count = 0
    
    # 3. Process & Store
    for idx, content in enumerate(chunks_text):
        # Generate embedding
        emb_bytes = generate_embedding(content)
        if emb_bytes:
            embeddings_count += 1
            
        chunk = Chunk(
            lecture_notes_id=lecture_note_id,
            chunk_index=idx,
            text=content,
            keywords=None, # Placeholder for future
            embedding=emb_bytes
        )
        db.add(chunk)
    
    db.commit()
    
    return len(chunks_text), embeddings_count
