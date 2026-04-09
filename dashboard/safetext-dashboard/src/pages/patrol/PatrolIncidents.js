import React, { useState } from "react";
import { Link } from "react-router-dom";
import { Users, MapPin, Home, Clock } from "lucide-react";
import "./PatrolIncidents.css";

function PatrolIncidents({ incidents, updateStatus, patrolUnits }) {
  // Mock unit statuses and locations to match the image exactly
  const [unitStatuses, setUnitStatuses] = useState({
    "P1": "ON-BREAK",
    "P2": "CURRENTLY ACTIVE",
    "P3": "CURRENTLY ACTIVE"
  });

  const handleStatusChange = (unitId, status) => {
    setUnitStatuses(prev => ({ ...prev, [unitId]: status }));
  };

  const getUnitIncidents = (unitId) => {
    return incidents.filter(i => i.assignedTo === unitId && i.status !== "Resolved");
  };

  const renderUnitCard = (unit) => {
    const status = unitStatuses[unit.id] || "CURRENTLY ACTIVE";
    const isActive = status === "CURRENTLY ACTIVE";
    const unitIncidents = getUnitIncidents(unit.id);

    return (
      <div key={unit.id} className="unit-card">
        <div className="unit-card-header">
          <div className="unit-name-section">
            <h3>{unit.name}</h3>
          </div>
          <select 
            className="status-dropdown" 
            value={status} 
            onChange={(e) => handleStatusChange(unit.id, e.target.value)}
          >
            <option value="ON-BREAK">ON-BREAK</option>
            <option value="CURRENTLY ACTIVE">CURRENTLY ACTIVE</option>
          </select>
        </div>

        <div className={`status-badge-inline ${isActive ? 'status-active-bg' : 'status-break-bg'}`}>
          {isActive ? 'ACTIVE' : 'ON BREAK'}
        </div>

        <div className="unit-location">
          <MapPin size={16} />
          <span>{unit.location}</span>
        </div>

        <div className="select-case-title">SELECT CASE FROM BELOW</div>

        <div className="cases-container">
          {unitIncidents.length > 0 ? (
            unitIncidents.map((incident) => (
              <div key={incident.id} className="mini-case-card">
                <p>{incident.text}</p>
                <div className="case-btn-row">
                  <button 
                    className="case-action-btn btn-accept"
                    onClick={() => updateStatus(incident.id, "In Progress")}
                  >
                    Accept
                  </button>
                  <button 
                    className="case-action-btn btn-reject"
                    onClick={() => updateStatus(incident.id, "Pending")}
                  >
                    Reject
                  </button>
                </div>
                <div className={`case-status-text ${incident.status === 'In Progress' ? 'text-accepted' : 'text-rejected'}`}>
                  {incident.status === 'In Progress' ? 'Case Accepted' : 'Case Rejected'}
                </div>
              </div>
            ))
          ) : (
            <div className="empty-cases-state">
              <p>No active cases assigned.</p>
            </div>
          )}
        </div>

        {!isActive && (
          <div className="break-notice">
            <Clock size={16} />
            <span>Currently on break. Resume status to handle cases.</span>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="incident-handling-container">
      <header className="incident-handling-header">
        <div className="header-left">
          <div className="handling-icon">
            <Users size={28} />
          </div>
          <div>
            <h2>Incident Handling</h2>
            <p>View all the assigned/incoming cases for your unit</p>
          </div>
        </div>
        <Link to="/" className="back-home-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </header>

      <div className="unit-cards-grid">
        {patrolUnits.map(unit => renderUnitCard(unit))}
      </div>
    </div>
  );
}

export default PatrolIncidents;
