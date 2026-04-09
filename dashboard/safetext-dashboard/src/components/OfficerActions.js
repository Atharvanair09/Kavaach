import React from "react";

function OfficerActions({ incident, updateStatus }) {

  return (
    <div style={{ marginTop: "10px" }}>

      <button onClick={() => updateStatus(incident.id, "Assigned")}>
        Assign Officer
      </button>

      <button onClick={() => updateStatus(incident.id, "In Progress")}
        style={{ marginLeft: "10px" }}>
        Dispatch Patrol
      </button>

      <button onClick={() => updateStatus(incident.id, "Resolved")}
        style={{ marginLeft: "10px" }}>
        Mark Resolved
      </button>

    </div>
  );
}

export default OfficerActions;