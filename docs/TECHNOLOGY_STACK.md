# 🛡️ Kavaach — Technology Stack Documentation

This document provides a detailed overview of the technologies used in the Kavaach project, explaining their roles and the rationale behind their selection.

---

## 📱 Mobile Application (Flutter & Dart)

### **Flutter**
*   **Role**: The core framework for the mobile application.
*   **Why**: Flutter was chosen for its cross-platform capabilities, allowing a single codebase to serve both Android and iOS. Its rich UI library and high-performance rendering engine (Impeller/Skia) are essential for creating the premium, glassmorphic UI that provides a calming experience for users in distress.

### **Dart**
*   **Role**: The programming language for the mobile app.
*   **Why**: Dart's fast execution and developer-friendly features like Sound Null Safety make it ideal for safety-critical applications where crashes must be minimized.

---

## ⚙️ Backend Services (Node.js & Python)

### **Node.js (Express)**
*   **Role**: The main orchestration server.
*   **Why**: Express acts as the "brain" of the operation, coordinating communication between the mobile app, the ML model, and the Firestore database. Its non-blocking I/O is perfect for handling multiple simultaneous chat sessions.

### **Python (FastAPI)**
*   **Role**: Dedicated ML serving API.
*   **Why**: Python is the industry standard for Machine Learning. FastAPI was selected for its high performance and speed, ensuring that the BERT model can classify user distress levels in near real-time (sub-500ms latency).

---

## 🤖 Machine Learning (Natural Language Processing)

### **Fine-tuned MobileBERT**
*   **Role**: Real-time distress classification.
*   **Why**: Unlike traditional keyword-based triggers, BERT understands context, sentiment, and intent. The "Mobile" variant is specifically used because it offers a significant reduction in model size and latency compared to standard BERT-base, without sacrificing accuracy.
*   **Frameworks**: PyTorch & HuggingFace Transformers.

### **OpenRouter (Jarvis AI)**
*   **Role**: Conversational support agent.
*   **Why**: While the BERT model detects *risk*, Jarvis provides *empathy*. OpenRouter allows us to integrate state-of-the-art LLMs (like GPT-4 or Claude) to act as a placeholder companion until professional help arrives.

---

## ☁️ Cloud & Infrastructure

### **Firebase Firestore**
*   **Role**: Real-time NoSQL Database.
*   **Why**: Essential for the "Real-time SOS" feature. When a user triggers an alert, Firestore synchronizes that data to the NGO dashboard within milliseconds, eliminating the need for manual page refreshes in emergency situations.

### **Firebase Authentication**
*   **Role**: Secure user identity management.
*   **Why**: Provides robust security right out of the box, ensuring that sensitive user data—like emergency contacts—is protected by Google-grade security protocols.

---

## 📊 Administration Dashboard (React)

### **React.js**
*   **Role**: Frontend framework for the monitoring dashboard.
*   **Why**: React's component-based architecture and mature ecosystem (like `lucide-react`) allow us to build a visually high-fidelity "Command Center" style interface for NGO operators.

### **Leaflet & React-Leaflet**
*   **Role**: Interactive Mapping.
*   **Why**: Used to visualize SOS alerts on a live map. Leaflet's lightweight footprint ensures the dashboard remains responsive even when tracking multiple incidents simultaneously.

---

## 📡 Connectivity & Integration

### **Ngrok**
*   **Role**: Secure tunnel for local development.
*   **Why**: Necessary for exposing our local backend to external SMS services (like TextBee) during development, allowing for end-to-end testing of the offline SMS trigger functionality.

### **Multilingual Support (Translation API)**
*   **Role**: Cross-language distress detection.
*   **Why**: By translating non-English messages before they reach the BERT model, we ensure that Kavaach remains effective for users regardless of their native language.

---

## 🛡️ Privacy & Security Measures

*   **Anonymous IDs**: No personal identifying information (PII) is stored in the database by default.
*   **Stealth Mode**: The app utilizes `shared_preferences` for quick-exit cues and stealth icons, allowing users to disguise the app as a harmless utility.
*   **Sensors (Shake Detection)**: Uses `sensors_plus` and `shake` Flutter packages to allow users to trigger alerts without looking at their screens.
