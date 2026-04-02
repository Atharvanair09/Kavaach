# import sys
# import json
from flask import Flask, request, jsonify
import torch
import torch.nn.functional as F
from transformers import BertTokenizer, BertForSequenceClassification

# Path to your trained model
MODEL_PATH = "./ml-model/model/jarvis"
print("Loading model")

# Load tokenizer and model
tokenizer = BertTokenizer.from_pretrained(MODEL_PATH)
model = BertForSequenceClassification.from_pretrained(MODEL_PATH)
model.eval()
print("Model loaded")

@app.route("/predict", methods=["POST"])
def predict_api():
    data = request.get_json()
    text = data["text"]

    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)

    with torch.no_grad():
        outputs = model(**inputs)

    # logits = outputs.logits
    # prediction = torch.argmax(logits, dim=1).item()

    probs = F.software(outputs.logits, dim=1)
    confidence, prediction = torch.max(probs, dim=1)
    
    confidence_val = confidence.item()
    prediction_val = prediction.item()

    # Example mapping
    risk_map = {
        0: "low",
        1: "medium",
        2: "high"
    }
    risk = risk_map[prediction_val]

    return jsonify{{
        "risk": risk,
        "emotion": "neutral",
        "confidence": confidence_val,
    }}

if __name__ == "__main__":
    app.run(port=5500, debug=True)

# Read message from Node.js
# message = sys.stdin.read()

# result = predict(message)

# print(json.dumps(result))