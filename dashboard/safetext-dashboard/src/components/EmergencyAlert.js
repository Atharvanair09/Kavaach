import React from "react";

function EmergencyAlert({ show }) {
  if (!show) return null;

  return (
    <div style={{
      backgroundColor: "#ff4d4d",
      color: "white",
      padding: "12px",
      marginBottom: "20px",
      borderRadius: "6px",
      fontWeight: "bold",
      textAlign: "center"
    }}>
      🚨 HIGH RISK INCIDENT DETECTED
    </div>
  );
}

export default EmergencyAlert;