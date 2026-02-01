import json
import re
from typing import List, Dict, Optional
from llama_cpp import Llama
from api.config import PHI3_MODEL_PATH
import os
import multiprocessing

# Adjust path relative to where execution happens or absolute path
MODEL_PATH = PHI3_MODEL_PATH

_phi3_model = None

def get_phi3_model():
    global _phi3_model
    if _phi3_model is None:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Phi-3 model not found at {MODEL_PATH}")
        print(f"Loading Phi-3 model from {MODEL_PATH}...")
        
        # Performance Optimization from User
        try:
            _phi3_model = Llama(
                model_path=MODEL_PATH,
                n_ctx=1024, # Adequate and fast context
                n_threads=multiprocessing.cpu_count(), # Use all CPU threads
                n_batch=512, # Critical for speed
                verbose=False,
                temperature=0.1 # More consistent JSON generation
            )
        except Exception as e:
            print(f"Failed to load model: {e}")
            raise e
            
    return _phi3_model

def clean_json_output(text: str) -> str:
    """
    Attempts to extract validity JSON from the model output.
    """
    # Look for JSON block
    match = re.search(r'\{.*\}', text, re.DOTALL)
    if match:
        return match.group(0)
    return text

def build_prompt(lecture_chunk: str, difficulty: str) -> str:
    """
    Constructs a Phi-3 chat template prompt for MCQ generation.
    """
    return f"""
<|system|>
You are an AI model that generates strictly valid JSON outputs for multiple-choice questions.
Never include explanations or any text outside the JSON object.
<|end|>

<|user|>
Generate one multiple-choice question (MCQ) from the given lecture text chunk.

Your output must be valid JSON with the following fields:
- question
- options (exactly 4 strings)
- correct (index 0-3)
- difficulty (Easy, Medium, Hard)
- time_secs (integer)

The MCQ must match the requested difficulty.
Provide only the JSON object.

Lecture Chunk:
{lecture_chunk}

Difficulty: {difficulty}
<|end|>

<|assistant|>
""".strip()

def generate_mcq_phi3(context_chunk: str, difficulty: str = "Medium") -> Optional[Dict]:
    """
    Generates a single MCQ using the Phi-3 model.
    """
    model = get_phi3_model()
    
    prompt = build_prompt(context_chunk, difficulty)
    
    response = model(
        prompt,
        max_tokens=256,
        stop=["<|end|>"],
        echo=False
    )
    
    output_text = response['choices'][0]['text'].strip()
    
    # Try to parse JSON
    try:
        json_str = clean_json_output(output_text)
        data = json.loads(json_str)
        
        # Validation
        if "options" in data and isinstance(data["options"], list) and len(data["options"]) == 4:
            # Map index correct to A,B,C,D if needed or keep as index
            
            # Map index to letter
            idx = data.get("correct")
            if isinstance(idx, int) and 0 <= idx <= 3:
                data["correct"] = chr(65 + idx) # 0->A, 1->B...
            
            # Convert list to dict for service compatibility
            opts = data["options"]
            data["options"] = {
                "A": opts[0],
                "B": opts[1],
                "C": opts[2],
                "D": opts[3]
            }
            
            return data
    except json.JSONDecodeError:
        print(f"Failed to parse JSON: {output_text}")
    except Exception as e:
        print(f"Error processing output: {e}")
        
    return None
