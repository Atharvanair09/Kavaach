import sys
import json
from flask import Flask, request, jsonify
import torch
import torch.nn.functional as F
from transformers import BertTokenizer, BertForSequenceClassification

app = Flask(__name__)

# Path to your trained model
MODEL_PATH = "../ml-model/model/jarvis"
print("Loading model")

# Load tokenizer and model
tokenizer = BertTokenizer.from_pretrained(MODEL_PATH)
model = BertForSequenceClassification.from_pretrained(MODEL_PATH)
model.eval()
print("Model loaded")

@app.route("/predict", methods=["POST"])
def predict_api():
    data = request.get_json()
    text = data.get("text", data.get("message", ""))

    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)

    with torch.no_grad():
        outputs = model(**inputs)

    probs = F.softmax(outputs.logits, dim=1)
    confidence, prediction = torch.max(probs, dim=1)
    
    confidence_val = confidence.item()
    prediction_val = prediction.item()

    # Example mapping (adjust to match your Jarivs model classes)
    risk_map = {
        0: "low",
        1: "medium",
        2: "high"
    }
    risk = risk_map.get(prediction_val, "low")

    return jsonify({
        "risk": risk,
        "emotion": "neutral",
        "confidence": confidence_val,
    })

if __name__ == "__main__":
    app.run(port=5500, debug=True)