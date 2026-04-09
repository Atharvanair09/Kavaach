import React from "react";
import { Link } from "react-router-dom";
import { AlertTriangle, MapPin, PhoneCall, ShieldAlert, Users, Home } from "lucide-react";

function Emergency({ incidents = [] }) {
  const emergencyCases = incidents.filter(
    (incident) => incident.priority?.toLowerCase() === "high"
  );

  return (
    <div className="page-container dashboard-page">
      <header className="emergency-header flex-header">
        <div className="紧急-title-wrapper">
          <ShieldAlert className="紧急-icon pulse-red" size={48} />
          <div>
            <h1>Emergency Response Center</h1>
            <p className="subtitle">High-priority incidents requiring immediate attention.</p>
          </div>
        </div>
        <div className="header-actions">
          <Link to="/" className="btn btn-outline btn-sm back-btn">
            <Home size={18} />
            <span>Back to Home</span>
          </Link>
          <div className="emergency-status-badge">
            <span className="dot pulse-red"></span>
            LIVE MONITORING ACTIVE
          </div>
        </div>
      </header>

      {emergencyCases.length > 0 ? (
        <div className="emergency-alert-banner">
          <AlertTriangle size={24} />
          <span>ATTENTION: {emergencyCases.length} Critical Incident{emergencyCases.length > 1 ? 's' : ''} Detected</span>
        </div>
      ) : null}

      <div className="emergency-grid">
        {emergencyCases.length === 0 ? (
          <div className="card empty-emergency-card">
            <ShieldAlert size={64} className="muted-icon" />
            <h3>All Systems Clear</h3>
            <p>No high-priority emergency incidents reported at this time.</p>
          </div>
        ) : (
          emergencyCases.map((incident, index) => (
            <div key={index} className="card critical-incident-card">
              <div className="critical-header">
                <span className="critical-tag">CRITICAL ALERT</span>
                <span className="incident-time">{incident.timestamp}</span>
              </div>
              
              <div className="critical-body">
                <h3 className="incident-text">{incident.text}</h3>
                <div className="incident-meta">
                  <div className="meta-item">
                    <MapPin size={16} />
                    <span>Location: Detected via IP/GPS (Placeholder)</span>
                  </div>
                  <div className="meta-item">
                    <Users size={16} />
                    <span>Reported by: User App</span>
                  </div>
                </div>
              </div>

              <div className="critical-actions">
                <button className="btn btn-danger">
                  <PhoneCall size={18} />
                  Dispatch Emergency Personnel
                </button>
                <div className="secondary-actions">
                  <button className="btn btn-outline">Notify Local Police</button>
                  <button className="btn btn-outline">Alert Emergency Contacts</button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      <section className="emergency-resources">
        <h2>Emergency Quick-Access</h2>
        <div className="resources-grid">
          <div className="resource-mini-card">
            <strong>Police Hotline</strong>
            <span>100 / 112</span>
          </div>
          <div className="resource-mini-card">
            <strong>Women Helpline</strong>
            <span>1091</span>
          </div>
          <div className="resource-mini-card">
            <strong>Ambulance</strong>
            <span>102</span>
          </div>
        </div>
      </section>
    </div>
  );
}

export default Emergency;