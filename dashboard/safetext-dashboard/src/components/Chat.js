import React, { useState } from "react";
import "./Chat.css";

function Chat() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  const classifyIntent = (message) => {
  const text = message.toLowerCase();

  if (text.match(/hello|hi|hey/)) return "greeting";
  if (text.match(/emergency|danger|unsafe|help me/)) return "emergency";
  if (text.match(/harass|stalk|abuse|molest/)) return "harassment";
  if (text.match(/fir|complaint|police|legal/)) return "legal_help";
  if (text.match(/injured|hurt|bleeding|medical/)) return "medical_help";

  return "default";
};

const getBotResponse = (intent) => {
  switch (intent) {
    case "greeting":
      return "Hello! I'm here to support you. Please tell me your concern.";

    case "emergency":
      return "🚨 If you are in immediate danger, call 112 immediately. You can also contact Women Helpline: 181.";

    case "harassment":
      return "You can report harassment to the nearest police station or call 1091 Women Helpline.";

    case "legal_help":
      return "To file an FIR, visit your nearest police station or use online police complaint portals available in your state.";

    case "medical_help":
      return "If you are injured, please seek medical attention immediately. Call 108 for ambulance services.";

    default:
      return "I understand. Could you please provide more details so I can assist you better?";
  }
};

 const handleSend = () => {
  if (input.trim() === "") return;

  const userMessage = { text: input, sender: "user" };
  const intent = classifyIntent(input);
  const botReply = getBotResponse(intent);

  setInput("");

  setMessages((prev) => [
    ...prev,
    userMessage,
    { text: "Typing...", sender: "bot", typing: true }
  ]);

  setTimeout(() => {
    setMessages((prev) =>
      prev
        .filter((msg) => !msg.typing)
        .concat({ text: botReply, sender: "bot" })
    );
  }, 1200);
};

  return (
    <div className="chat-container">
      <h2>Safety Chat Support</h2>

      <div className="chat-box">
        {messages.map((msg, index) => (
          <div key={index} className={`message ${msg.sender}`}>
            {msg.text}
          </div>
        ))}
      </div>

      <div className="chat-input">
        <input
          type="text"
          placeholder="Type your message..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
        />
        <button onClick={handleSend}>Send</button>
      </div>
    </div>
  );
}

export default Chat;