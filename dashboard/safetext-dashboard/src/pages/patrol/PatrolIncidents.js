import React, { useState } from "react";
import { Link } from "react-router-dom";
import { MapPin } from "lucide-react";

function PatrolIncidents({ incidents, updateStatus, patrolUnits, user }) {
  // Filter for incidents that are either Unassigned (Pending) or Assigned to a unit
  const activeIncidents = incidents.filter(i => 
    i.status === "Pending" || i.status === "In Progress"
  );

  const getPriorityColor = (priority) => {
    const p = (priority || "").toLowerCase();
    if (p === "high") return "red";
    if (p === "medium") return "orange";
    return "blue";
  };

  const handleAction = (id, status) => {
     updateStatus(id, status);
  };

  return (
    <div className="patrol-page-container">
      <div className="patrol-header">
        <h2>Incident Handling</h2>
        <p>Incoming case queue and unit assignments.</p>
      </div>

      <div className="patrol-widgets-grid grid-2-1">
        {/* Left column: Incoming Cases */}
        <div className="widget-card full-height-widget">
          <div className="widget-header">
            <h3>Unit Task Queue</h3>
            <span className="live-dot-text"><span className="dot green-dot"></span> LIVE UPDATES</span>
          </div>
          
          <div className="incident-queue-list">
             {activeIncidents.length > 0 ? (
               activeIncidents.map((c, index) => {
                const color = getPriorityColor(c.priority);
                const assignedUnit = patrolUnits.find(p => p.id === c.assignedTo);
                
                return (
                  <div key={c.id || index} className={`queue-card border-top-${color}`}>
                     <div className="queue-card-top">
                        <div className="queue-card-meta">
                           <span className={`dot ${color}-dot`}></span>
                           <span className="case-id">CASE-{c.id?.substring(0, 6) || `00${index+1}`}</span>
                           {assignedUnit && <span className="badge-unit-assigned">{assignedUnit.name}</span>}
                        </div>
                        <span className="queue-time">{c.timestamp}</span>
                     </div>
                     <h4 className="queue-title">{c.intent}</h4>
                     <p className="queue-location">
                        <MapPin size={14} className="icon-subdued" />
                        <span>{c.location || "Location pending tracking..."}</span>
                     </p>
                     
                     <div className="queue-actions">
                        {c.status === "Pending" ? (
                          <button className="queue-btn primary-btn" onClick={() => handleAction(c.id, "In Progress")}>Accept Task</button>
                        ) : (
                          <button className="queue-btn success-btn" onClick={() => handleAction(c.id, "Resolved")}>Mark Resolved</button>
                        )}
                        <button className="queue-btn outline-btn">Details</button>
                     </div>
                  </div>
                )
               })
             ) : (
               <div className="empty-queue">
                  <p>All clear. No active incidents assigned.</p>
               </div>
             )}
          </div>
        </div>

        {/* Right column: Scene Control */}
        <div className="widget-card mark-scene-widget">
          <div className="widget-header">
            <h3>Unit Visibility</h3>
          </div>
          <div className="scene-content">
             <p>Set your current field status for the dispatch center.</p>
             <div className="scene-buttons">
                <button className="scene-btn secure">Mark Secure</button>
                <button className="scene-btn unsafe">Incident Area</button>
             </div>
             <p className="scene-status">Status: <strong>Available</strong></p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default PatrolIncidents;
