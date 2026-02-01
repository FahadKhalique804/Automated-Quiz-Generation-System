from sentence_transformers import SentenceTransformer
import numpy as np

# Load model once (cached)
model = SentenceTransformer("all-MiniLM-L6-v2")

def generate_embedding(text: str) -> bytes:
    """
    Generates an embedding vector (list of floats) and converts it to bytes
    for saving into MySQL LONGBLOB.
    """
    if not text or text.strip() == "":
        return None

    vector = model.encode(text)  # numpy float32 array
    return vector.tobytes()      # convert to binary for MySQL
