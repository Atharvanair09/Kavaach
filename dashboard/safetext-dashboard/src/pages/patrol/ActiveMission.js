import React from "react";
import { Crosshair, MapPin, User, ShieldAlert, Home } from "lucide-react";
import { Link } from "react-router-dom";

function ActiveMission() {
  return (
    <div className="page-container dashboard-page">
      <header className="flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <div className="header-icon primary" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '48px', height: '48px', borderRadius: '12px', backgroundColor: '#eff6ff', color: '#3b82f6' }}>
             <Crosshair size={24} />
          </div>
          <div className="header-text">
            <div className="header-badge">Live Case Tracking</div>
            <h1 style={{margin: '0.25rem 0', fontSize: '1.75rem'}}>Active Mission</h1>
            <p className="subtitle" style={{margin: 0}}>Track and manage your current case in real-time.</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </header>

      <div className="card" style={{marginTop: '2rem'}}>
        <div style={{display: 'flex', justifyContent: 'space-between', borderBottom: '1px solid #e2e8f0', paddingBottom: '1rem', marginBottom: '1rem'}}>
           <h3>Incident #ST-9912</h3>
           <span className="badge badge-high" style={{backgroundColor: '#fee2e2', color: '#dc2626', padding: '4px 12px', borderRadius: '12px', fontWeight: 'bold'}}>HIGH PRIORITY</span>
        </div>
        
        <div style={{display: 'grid', gridTemplateColumns: 'minmax(300px, 1fr) 1fr', gap: '2rem'}}>
          <div>
            <h4 style={{marginBottom: '0.5rem', color: '#64748b'}}>Description</h4>
            <p style={{fontSize: '1.1rem', fontWeight: 500}}>Medical emergency reported at structural fire location.</p>
            
            <div style={{marginTop: '2rem', display: 'flex', flexDirection: 'column', gap: '1rem'}}>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <MapPin size={18} className="muted-icon" /> <span>Downtown Sector 4, 8th Ave.</span>
              </div>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                <User size={18} className="muted-icon" /> <span>Reporter: Sarah Jenkins</span>
              </div>
              <div style={{display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#dc2626'}}>
                <ShieldAlert size={18} /> <span>Caution: Potential Crowd Congestion</span>
              </div>
            </div>
          </div>
          
          <div style={{backgroundColor: '#f8fafc', padding: '1.5rem', borderRadius: '8px'}}>
            <h4 style={{marginBottom: '1rem', color: '#64748b'}}>Mission Timeline</h4>
            <div style={{display: 'flex', flexDirection: 'column', gap: '1rem', borderLeft: '2px solid #cbd5e1', paddingLeft: '1rem', marginLeft: '0.5rem'}}>
               <div style={{position: 'relative'}}>
                 <div style={{position: 'absolute', left: '-1.35rem', top: '0.2rem', width: '0.6rem', height: '0.6rem', borderRadius: '50%', backgroundColor: '#cbd5e1'}}></div>
                 <span style={{fontSize: '0.85rem', color: '#64748b'}}>14:30 PM</span>
                 <p style={{margin: '0.25rem 0'}}>Case Logged by Command Center</p>
               </div>
               <div style={{position: 'relative'}}>
                 <div style={{position: 'absolute', left: '-1.35rem', top: '0.2rem', width: '0.6rem', height: '0.6rem', borderRadius: '50%', backgroundColor: '#3b82f6'}}></div>
                 <span style={{fontSize: '0.85rem', color: '#64748b'}}>14:32 PM</span>
                 <p style={{margin: '0.25rem 0', fontWeight: 600}}>Mission Accepted by Alpha Unit</p>
               </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default ActiveMission;
