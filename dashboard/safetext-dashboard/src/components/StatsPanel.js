import React from "react";

function StatsPanel({ incidents }) {

  const total = incidents.length;

  const high = incidents.filter(
    i => i.priority?.toLowerCase() === "high"
  ).length;

  const resolved = incidents.filter(
    i => i.status === "Resolved"
  ).length;

  return (
    <div style={{
      display: "flex",
      gap: "20px",
      marginBottom: "20px"
    }}>

      <div>Total Incidents: {total}</div>

      <div>High Priority: {high}</div>

      <div>Resolved: {resolved}</div>

    </div>
  );
}

export default StatsPanel;