import React, { useState } from "react";
import { RefreshCw, CheckCircle, Clock, Navigation, Shield, Home } from "lucide-react";
import { Link } from "react-router-dom";

function StatusUpdate() {
  const [currentStatus, setCurrentStatus] = useState("Accepted");

  const statuses = [
    { label: "Accepted", icon: CheckCircle, color: "#3b82f6", bg: "#eff6ff" },
    { label: "On Route", icon: Navigation, color: "#8b5cf6", bg: "#f5f3ff" },
    { label: "On Scene", icon: Shield, color: "#d97706", bg: "#fffbeb" },
    { label: "Resolved", icon: CheckCircle, color: "#16a34a", bg: "#dcfce7" },
  ];

  return (
    <div className="page-container dashboard-page">
      <header className="flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <div className="header-icon primary" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '48px', height: '48px', borderRadius: '12px', backgroundColor: '#eff6ff', color: '#3b82f6' }}>
             <RefreshCw size={24} />
          </div>
          <div className="header-text">
            <h1 style={{margin: '0.25rem 0', fontSize: '1.75rem'}}>Status Control</h1>
            <p className="subtitle" style={{margin: 0}}>Update your current operational phase.</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </header>

      <div className="card" style={{marginTop: '2rem'}}>
         <h3 style={{marginBottom: '1.5rem', textAlign: 'center'}}>Current Phase: <span style={{color: '#3b82f6'}}>{currentStatus}</span></h3>
         
         <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem'}}>
            {statuses.map((status) => (
              <button 
                key={status.label}
                onClick={() => setCurrentStatus(status.label)}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  padding: '2rem',
                  border: `2px solid ${currentStatus === status.label ? status.color : '#e2e8f0'}`,
                  borderRadius: '12px',
                  backgroundColor: currentStatus === status.label ? status.bg : 'white',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  boxShadow: currentStatus === status.label ? '0 4px 6px -1px rgba(0,0,0,0.1)' : 'none'
                }}
              >
                <div style={{
                  padding: '1rem',
                  borderRadius: '50%',
                  backgroundColor: status.bg,
                  color: status.color,
                  marginBottom: '1rem'
                }}>
                  <status.icon size={32} />
                </div>
                <strong style={{fontSize: '1.1rem', color: '#1e293b'}}>{status.label}</strong>
                {currentStatus === status.label && <span style={{marginTop: '0.5rem', fontSize: '0.8rem', color: status.color, fontWeight: 'bold'}}>ACTIVE</span>}
              </button>
            ))}
         </div>

         <div style={{marginTop: '3rem', borderTop: '1px solid #e2e8f0', paddingTop: '1.5rem', display: 'flex', justifyContent: 'center'}}>
           <button className="btn btn-danger btn-lg" style={{padding: '1rem 3rem'}}>
             REQUEST BACKUP
           </button>
         </div>
      </div>
    </div>
  );
}

export default StatusUpdate;
