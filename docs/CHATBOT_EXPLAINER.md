# 🤖 Jarvis: The Intelligence Behind Kavaach

This guide provides an in-depth breakdown of how the Kavaach chatbot (Jarvis) works. It is designed to help you explain the system to judges, highlighting technical sophistication, ethical considerations, and user safety.

---

## 🏗️ 1. The "Dual-Engine" Architecture
Kavaach doesn't just use one AI; it uses a **Hybrid Duo** to balance speed and empathy.

### **Engine A: The Guard (BERT Model)**
*   **What it is**: A fine-tuned **MobileBERT** (Transformer) model.
*   **Role**: **Risk Classification**. 
*   **How it works**: It processes the user's message and calculates a "Risk Score" (Low, Medium, High) in under 500ms.
*   **Why BERT?**: Unlike simple "search for words" bots, BERT understands **context**. 
    *   *Example*: "I’m hit" (High Risk) vs. "I hit a milestone" (Low Risk). A keyword bot would fail here; BERT succeeds.

### **Engine B: The Companion (LLM - GPT-4o-mini via OpenRouter)**
*   **What it is**: A Large Language Model (Generative AI).
*   **Role**: **Empathetic Conversation**.
*   **How it works**: It takes the Risk Level from Engine A and generates a response that is supportive, non-repetitive, and human-like.
*   **Why an LLM?**: In high-stress situations, users need to feel heard. A robotic "Call 100" response can cause panic. Jarvis provides a calming "bridge" while help is on the way.

---

## 🛠️ 2. Core Intelligent Features

### **A. Multilingual Translation Pipeline**
*   **The Problem**: ML models like BERT are most accurate in English.
*   **The Solution**: If a user types in Hindi, Spanish, or Marathi, Jarvis uses a translation layer to convert it to English for Engine A (to ensure 99% accuracy) while Engine B responds in the user's **original language** to maintain trust.

### **B. Tier-Based UI & Action Response**
The app's behavior changes dynamically based on the AI's detection:
*   🟢 **Green (Low)**: Supportive chat, general advice.
*   🟡 **Yellow (Medium)**: Proactively displays "Safe Haven" cards (Nearby Police/Hospitals) and offers to share location with trusted contacts.
*   🔴 **Red (High)**: **Silent Escalation**. Triggers the SOS system, notifies emergency contacts, and broadcasts live GPS without the user needing to press a single button.

### **C. Offline SMS Bridge (The "Data-Free" Safety Net)**
*   **How it works**: If the user has no internet, they can text a dedicated number. Our backend (via TextBee/Ngrok) processes the SMS as if it were a chat, run the same AI checks, and texts back safety instructions and landmarks.

### **D. Stealth Mode (Privacy by Design)**
*   **Zero PII**: We don't store names or phone numbers in the chat history—only anonymous session IDs.
*   **Covert UI**: Responses are kept short so they don't look like an "emergency app" from a distance.

---

## 🎓 3. Judge's Q&A (Preparing for the "Grilling")

### **Q1: "Why use BERT *and* an LLM? Isn't an LLM enough?"**
> **Answer**: "LLMs are great at talking, but they can be slow and expensive for high-speed classification. By using a lightweight **MobileBERT** model for the primary safety check, we get a decision in milliseconds. We only use the LLM to wrap that decision in a human-friendly response. This 'Separation of Concerns' makes the app faster and more reliable."

### **Q2: "What if the AI hallucinations or gives wrong advice?"**
> **Answer**: "We have 'Safe Rails' in place. Our system prompt strictly forbids the AI from giving medical or legal advice. More importantly, the **Action Layer** (like triggering SOS or showing maps) is controlled by hard logic based on the BERT classification, not just the LLM's text. We also provide 'One-Tap' fallback buttons for helplines as a secondary safety measure."

### **Q3: "How do you handle privacy and data security?"**
> **Answer**: "Privacy is our core feature. We use **Anonymous Session Tracking**. Chat logs are stored against a random UUID, not a user profile. Furthermore, the app includes a 'Quick Exit' feature and uses stealth icons so the app doesn't attract unwanted attention from an aggressor."

### **Q4: "How does 'Offline Mode' work without a server?"**
> **Answer**: "It doesn't work *without* a server, but it works *without the user's mobile data*. We use a **Webhook-to-SMS Gateway**. When a user sends an SMS, it hits our cloud server, runs the AI pipeline, and sends a return SMS with instructions. This is critical for users in areas with poor network coverage or those who have run out of data."

### **Q5: "How did you fine-tune the model to understand 'distress'?"**
> **Answer**: "We used datasets focused on crisis intervention and mental health support. We fine-tuned the model to recognize 'micro-markers' of danger—phrases that indicate a lack of control, physical threat, or stalking—ensuring it differentiates between a casual conversation and a genuine emergency."

---

## 💡 Quick Technical Specs for Judges:
- **ML Architecture**: Transformer (MobileBERT)
- **Frameworks**: Flutter (Mobile), FastAPI (ML API), Express (Backend)
- **Database**: Firebase Firestore (Real-time syncing)
- **Deployment**: Local tunnel (Ngrok) for SMS webhooks, allowing for agile testing.
