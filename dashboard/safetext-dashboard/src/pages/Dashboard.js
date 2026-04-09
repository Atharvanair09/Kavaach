import React, { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import {
  Activity,
  AlertOctagon,
  CheckCircle2,
  Clock,
  Inbox,
  Shield,
  UserCheck,
  ChevronDown,
  Home
} from "lucide-react";

import { collection, onSnapshot } from "firebase/firestore";
import { db } from "../services/firebase";

function Dashboard({ incidents, updateStatus, role, user, assignPatrol, patrolUnits }) {
  const [showAssignModal, setShowAssignModal] = useState(null);

  const isAdmin = role === "admin";
  const sourceIncidents = incidents;

  const userIncidents = isAdmin
    ? sourceIncidents
    : sourceIncidents.filter(
        (i) => i.assignedTo === user.id || i.assignedTo === "P1"
      );

  const pendingCases = userIncidents.filter(
    (incident) =>
      incident.status === "Pending" || incident.status === "In Progress"
  );

  const resolvedCases = userIncidents.filter(
    (incident) => incident.status === "Resolved"
  );

  const stats = [
    {
      label: "Total Incidents",
      value: userIncidents.length,
      icon: Inbox,
      color: "primary"
    },
    {
      label: "High Priority",
      value: userIncidents.filter((i) => i.priority === "High").length,
      icon: AlertOctagon,
      color: "danger"
    },
    {
      label: "Active Cases",
      value: pendingCases.length,
      icon: Activity,
      color: "warning"
    },
    {
      label: "Resolved",
      value: resolvedCases.length,
      icon: CheckCircle2,
      color: "success"
    }
  ];

  return (
    <div className="page-container dashboard-page">
      <header className="dashboard-header flex-header">
        <div className="header-text">
          <div className="header-badge">
            {role === "admin"
              ? "Monitoring Command Center"
              : "Patrol Response Unit"}
          </div>
          <h1>
            {role === "admin" ? "Strategic Dashboard" : "Your Patrol Log"}
          </h1>
          <p className="subtitle">
            {role === "admin"
              ? "Assign resources and manage global safety response."
              : "Respond to incidents assigned to your patrol hub."}
          </p>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </header>

      {isAdmin && (
        <section className="patrol-monitoring shadow-sm card mb-3">
          <div className="section-header">
            <UserCheck className="section-icon primary" />
            <h2>Active Patrol Personnel</h2>
            <span className="live-pill">Live Monitoring</span>
          </div>
          <div className="patrol-mini-list">
            {patrolUnits.map((unit) => (
              <div key={unit.id} className="patrol-unit-pill">
                <div
                  className={`status-dot ${
                    unit.status === "Active" ? "success" : "muted"
                  }`}
                ></div>
                <div className="unit-info">
                  <strong>{unit.name}</strong>
                  <span>
                    {unit.location} • {unit.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      <div className="stats-grid">
        {stats.map((stat, idx) => (
          <div key={idx} className="card stat-card">
            <div className={`stat-icon-wrapper ${stat.color}`}>
              <stat.icon size={24} />
            </div>
            <div className="stat-info">
              <span className="stat-label">{stat.label}</span>
              <span className="stat-value">{stat.value}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="dashboard-content no-sidebar">
        <section className="dashboard-section">
          <div className="section-header">
            <Clock className="section-icon warning" />
            <h2>
              {isAdmin
                ? "Incoming Priority Alerts"
                : "Assigned Case Log"}
            </h2>
          </div>

          {pendingCases.length === 0 ? (
            <div className="empty-state">
              <Inbox size={48} className="empty-icon" />
              <p>No active incidents requiring immediate attention.</p>
            </div>
          ) : (
            <div className="cases-list-grid">
              {pendingCases.map((incident, index) => {
                const originalIndex = sourceIncidents.findIndex(
                  (i) => i.id === incident.id
                );
                const isAssigned = !!incident.assignedTo;
                const assignedUnit = patrolUnits.find(
                  (p) => p.id === incident.assignedTo
                );

                return (
                  <div
                    key={incident.id}
                    className="card incident-card enhanced-card"
                  >
                    <div className="incident-header">
                      <span
                        className={`badge badge-${incident.priority.toLowerCase()}`}
                      >
                        {incident.priority}
                      </span>
                      <span className="incident-time">
                        {incident.timestamp}
                      </span>
                    </div>

                    <div className="incident-body">
                      <h3>{incident.intent}</h3>
                      <p>{incident.text}</p>

                      {isAssigned && (
                        <div className="assignment-badge">
                          <Shield size={14} />
                          <span>
                            Unit: {assignedUnit?.name || "Local Response"}
                          </span>
                        </div>
                      )}
                    </div>

                    <div className="incident-footer">
                      <div
                        className={`status-badge status-${incident.status
                          .toLowerCase()
                          .replace(" ", "-")}`}
                      >
                        {incident.status}
                      </div>

                      <div className="actions">
                        {isAdmin && !isAssigned && (
                          <div className="dispatch-select-wrapper">
                            <button
                              className="btn btn-primary btn-sm"
                              onClick={() =>
                                setShowAssignModal(incident.id)
                              }
                            >
                              Dispatch Patrol{" "}
                              <ChevronDown size={14} />
                            </button>

                            {showAssignModal === incident.id && (
                              <div className="patrol-dropdown shadow-lg">
                                {patrolUnits.map((unit) => (
                                  <button
                                    key={unit.id}
                                    onClick={() => {
                                      assignPatrol(
                                        incident.id,
                                        unit.id
                                      );
                                      setShowAssignModal(null);
                                    }}
                                  >
                                    Assign {unit.name}
                                  </button>
                                ))}
                              </div>
                            )}
                          </div>
                        )}

                        {!isAdmin &&
                          incident.status === "Pending" && (
                            <button
                              className="btn btn-primary btn-sm"
                              onClick={() =>
                                updateStatus(
                                  incident.id,
                                  "In Progress"
                                )
                              }
                            >
                              Start Response
                            </button>
                          )}

                        <button
                          className="btn btn-outline btn-sm"
                          onClick={() =>
                            updateStatus(incident.id, "Resolved")
                          }
                        >
                          Confirm Resolution
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

export default Dashboard;