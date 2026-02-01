import os

USE_OPENAI = os.getenv("USE_OPENAI", "false").lower() in ("1","true","yes")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
PHI3_MODEL_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "ml_model", "Phi-3-mini-128k-instruct.Q4_K_M.gguf")

