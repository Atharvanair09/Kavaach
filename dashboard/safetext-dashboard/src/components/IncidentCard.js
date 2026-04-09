import React from "react";

function IncidentCard({ incident }) {

  return (
    <div style={{
      border: "1px solid #ddd",
      padding: "15px",
      marginBottom: "15px",
      borderRadius: "8px",
      backgroundColor: "#fff"
    }}>
      <h4>Case #{incident.id}</h4>

      <p><strong>Message:</strong> {incident.message}</p>

      <p><strong>Location:</strong> {incident.location}</p>

      <p><strong>Priority:</strong> {incident.priority}</p>

      <p><strong>Status:</strong> {incident.status}</p>

      <p><strong>Time:</strong> {incident.time}</p>

    </div>
  );
}

export default IncidentCard;