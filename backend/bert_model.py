from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
from transformers import BertTokenizer, BertForSequenceClassification

app = FastAPI()

MODEL_PATH = "../ml-model/model/jarvis"

try:
    tokenizer = BertTokenizer.from_pretrained(MODEL_PATH)
    model = BertForSequenceClassification.from_pretrained(MODEL_PATH)
    model.eval()
except Exception as e:
    print("Model loading failed:", e)

class RequestData(BaseModel):
    text: str

def predict(text):
    text = text.strip()

    if not text:
        return {"risk": "low", "emotion": "neutral", "confidence": 0}

    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)

    with torch.no_grad():
        outputs = model(**inputs)

    logits = outputs.logits
    probs = torch.softmax(logits, dim=1)

    prediction = torch.argmax(probs, dim=1).item()
    confidence = torch.max(probs).item()

    if prediction == 0:
        risk = "low"
    elif prediction == 1:
        risk = "medium"
    else:
        risk = "high"

    return {
        "risk": risk,
        "emotion": "neutral",
        "confidence": float(confidence)
    }

@app.get("/")
def home():
    return {"message": "BERT API running"}

@app.post("/predict")
def get_prediction(data: RequestData):
    try:
        return predict(data.text)
    except Exception:
        raise HTTPException(status_code=500, detail="Prediction failed")
