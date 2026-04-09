import React from "react";

function ChatViewer({ messages }) {

  if (!messages || messages.length === 0) {
    return <p>No conversation available</p>;
  }

  return (
    <div style={{
      border: "1px solid #ddd",
      padding: "10px",
      borderRadius: "6px",
      marginTop: "15px"
    }}>

      <h4>Conversation</h4>

      {messages.map((msg, index) => (
        <p key={index}>• {msg}</p>
      ))}

    </div>
  );
}

export default ChatViewer;