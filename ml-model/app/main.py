from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification

app = FastAPI(title="Kavaach ML Model API")

# Path to the trained model
MODEL_PATH = "../model/jarvis"

# Map model output labels to risk levels and emotions
# LABEL_0 = positive/safe, LABEL_1 = low risk, LABEL_2 = medium risk, LABEL_3 = high risk
LABEL_MAP = {
    "LABEL_0": {"risk": "low",    "emotion": "positive"},
    "LABEL_1": {"risk": "low",    "emotion": "neutral"},
    "LABEL_2": {"risk": "medium", "emotion": "distressed"},
    "LABEL_3": {"risk": "high",   "emotion": "danger"},
}

# Load the model and tokenizer
try:
    print(f"Loading model from {MODEL_PATH}...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)
    model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH)
    nlp_pipeline = pipeline("text-classification", model=model, tokenizer=tokenizer)
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model: {e}")
    nlp_pipeline = None

class PredictionRequest(BaseModel):
    text: str

@app.get("/")
def read_root():
    return {"message": "Kavaach ML Model API is running."}

@app.post("/predict")
def predict(request: PredictionRequest):
    if not nlp_pipeline:
        raise HTTPException(status_code=500, detail="Model is not loaded.")
    
    try:
        predictions = nlp_pipeline(request.text)
        top = predictions[0]  # e.g. {"label": "LABEL_3", "score": 0.97}
        mapped = LABEL_MAP.get(top["label"], {"risk": "low", "emotion": "neutral"})
        return {
            "risk": mapped["risk"],
            "emotion": mapped["emotion"],
            "label": top["label"],
            "score": round(top["score"], 4),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
