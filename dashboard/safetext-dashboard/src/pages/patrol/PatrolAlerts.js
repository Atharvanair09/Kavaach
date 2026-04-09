import React from "react";
import { AlertOctagon, ShieldAlert, AlertTriangle, Home } from "lucide-react";
import { Link } from "react-router-dom";

function PatrolAlerts() {
  const mockAlerts = [
    { id: 1, type: "critical", msg: "Code Red: Armed Suspect in vicinity of Sector 4. Proceed with extreme caution.", time: "2 mins ago" },
    { id: 2, type: "warning", msg: "Roadblock established on 5th street. Reroute approaching traffic.", time: "15 mins ago" },
    { id: 3, type: "info", msg: "All units: Shift change in 30 minutes at HQ.", time: "1 hour ago" },
  ];

  return (
    <div className="page-container dashboard-page">
      <header className="flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <div className="header-icon danger" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '48px', height: '48px', borderRadius: '12px', backgroundColor: '#fee2e2', color: '#dc2626' }}>
             <AlertOctagon size={24} />
          </div>
          <div className="header-text">
            <h1 style={{margin: '0.25rem 0', fontSize: '1.75rem'}}>Emergency Alerts</h1>
            <p className="subtitle" style={{margin: 0}}>Instant high-priority broadcasts from HQ.</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </header>

      <div className="card" style={{marginTop: '2rem'}}>
        <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
           {mockAlerts.map(alert => (
             <div key={alert.id} style={{
               padding: '1.5rem', 
               borderRadius: '8px', 
               borderLeft: `4px solid ${alert.type === 'critical' ? '#dc2626' : alert.type === 'warning' ? '#d97706' : '#3b82f6'}`,
               backgroundColor: alert.type === 'critical' ? '#fef2f2' : alert.type === 'warning' ? '#fffbeb' : '#eff6ff'
             }}>
               <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem'}}>
                 <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 'bold', color: alert.type === 'critical' ? '#991b1b' : alert.type === 'warning' ? '#92400e' : '#1e40af'}}>
                   {alert.type === 'critical' ? <ShieldAlert size={20} /> : <AlertTriangle size={20} />}
                   {alert.type.toUpperCase()} NOTIFICATION
                 </div>
                 <span style={{fontSize: '0.85rem', color: '#64748b'}}>{alert.time}</span>
               </div>
               <p style={{margin: 0, fontSize: '1.1rem', color: '#1e293b'}}>{alert.msg}</p>
               {alert.type === 'critical' && (
                 <button className="btn btn-danger btn-sm" style={{marginTop: '1rem'}}>Acknowledge Receipt</button>
               )}
             </div>
           ))}
        </div>
      </div>
    </div>
  );
}

export default PatrolAlerts;
