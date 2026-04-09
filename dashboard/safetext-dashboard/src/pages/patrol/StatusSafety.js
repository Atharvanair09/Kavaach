import React from "react";
import { Users, AlertCircle, CheckCircle, Clock, Shield, Activity, MapPin } from "lucide-react";

function StatusSafety({ incidents, patrolUnits }) {
  // --- Force Analytics ---
  const activeUnits = patrolUnits?.filter(u => u.availability === 'active').length || 0;
  const totalIncidents = incidents?.length || 0;
  const sosCount = incidents?.filter(i => i.isEmergency || i.title?.includes("SOS")).length || 0;
  const resolvedToday = incidents?.filter(i => i.status === 'Resolved').length || 0;

  return (
    <div className="patrol-page-container tactical" style={{ background: '#ffffff', minHeight: '100vh', padding: '2rem' }}>
      <div className="patrol-header" style={{ marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2rem', color: '#1e293b' }}>Mission Control</h2>
        <p style={{ color: '#64748b' }}>Force-wide situational awareness — Live Unit Deployment & Global Mission Feed.</p>
      </div>

      {/* 1. Force Analytics Highlights */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1.5rem', marginBottom: '2rem' }}>
        <div className="status-card" style={{ background: '#f8fafc', border: '1px solid #e2e8f0', padding: '1.5rem', borderRadius: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <Users size={20} color="#3b82f6" />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#3b82f6', background: 'rgba(59, 130, 246, 0.1)', padding: '2px 8px', borderRadius: '4px' }}>FORCE SIZE</span>
          </div>
          <h3 style={{ fontSize: '1.8rem', margin: 0, color: '#1e293b' }}>{patrolUnits?.length || 4}</h3>
          <p style={{ margin: '5px 0 0 0', fontSize: '0.85rem', color: '#64748b' }}>{activeUnits} units currently active</p>
        </div>

        <div className="status-card" style={{ background: '#fef2f2', border: '1px solid #fee2e2', padding: '1.5rem', borderRadius: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <AlertCircle size={20} color="#ef4444" />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#ef4444', background: 'rgba(239, 68, 68, 0.1)', padding: '2px 8px', borderRadius: '4px' }}>LIVE SOS</span>
          </div>
          <h3 style={{ fontSize: '1.8rem', margin: 0, color: '#1e293b' }}>{sosCount}</h3>
          <p style={{ margin: '5px 0 0 0', fontSize: '0.85rem', color: '#64748b' }}>High-priority emergencies</p>
        </div>

        <div className="status-card" style={{ background: '#f0fdf4', border: '1px solid #dcfce7', padding: '1.5rem', borderRadius: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <CheckCircle size={20} color="#10b981" />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#10b981', background: 'rgba(16, 185, 129, 0.1)', padding: '2px 8px', borderRadius: '4px' }}>RESOLVED</span>
          </div>
          <h3 style={{ fontSize: '1.8rem', margin: 0, color: '#1e293b' }}>{resolvedToday}</h3>
          <p style={{ margin: '5px 0 0 0', fontSize: '0.85rem', color: '#64748b' }}>Situations secured today</p>
        </div>

        <div className="status-card" style={{ background: '#eff6ff', border: '1px solid #dbeafe', padding: '1.5rem', borderRadius: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <Activity size={20} color="#2563eb" />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#2563eb', background: 'rgba(37, 99, 235, 0.1)', padding: '2px 8px', borderRadius: '4px' }}>LOAD</span>
          </div>
          <h3 style={{ fontSize: '1.8rem', margin: 0, color: '#1e293b' }}>{((totalIncidents / (patrolUnits?.length || 1)) * 10).toFixed(0)}%</h3>
          <p style={{ margin: '5px 0 0 0', fontSize: '0.85rem', color: '#64748b' }}>System utilization rate</p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '2rem' }}>
        
        {/* LEFT: GLOBAL MISSION FEED */}
        <div className="widget-card" style={{ background: '#ffffff', border: '1px solid #e2e8f0', padding: '1.5rem', borderRadius: '20px', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)' }}>
           <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h3 style={{ margin: 0, fontSize: '1.1rem', fontWeight: 800, color: '#1e293b', textTransform: 'uppercase', letterSpacing: '1px' }}>Global Mission Feed</h3>
              <span style={{ fontSize: '0.75rem', color: '#10b981', fontWeight: 700 }}><span className="live-pulse" style={{ display: 'inline-block', width: '8px', height: '8px', background: '#10b981', borderRadius: '50%', marginRight: '5px' }}></span> LIVE UPDATES</span>
           </div>
           
           <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {incidents?.length > 0 ? [...incidents].reverse().slice(0, 10).map((task, idx) => (
                <div key={idx} style={{ padding: '1.25rem', borderLeft: `4px solid ${task.status === 'Resolved' ? '#10b981' : task.status === 'Rejected' ? '#fbbf24' : '#3b82f6'}`, background: '#f8fafc', borderRadius: '4px 12px 12px 4px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                   <div>
                      <h4 style={{ margin: '0 0 4px 0', fontSize: '1rem', color: '#1e293b' }}>{task.title || (task.isEmergency ? "Emergency SOS" : "Patrol Assignment")}</h4>
                      <p style={{ margin: 0, fontSize: '0.85rem', color: '#64748b' }}>
                        Unit: <span style={{ fontWeight: 700, color: '#334155' }}>{task.assignedTo || 'Unassigned'}</span> • {task.text || task.message || 'Details pending...'}
                      </p>
                   </div>
                   <div style={{ textAlign: 'right' }}>
                      <span style={{ 
                        fontSize: '0.7rem', 
                        fontWeight: 800, 
                        padding: '4px 8px', 
                        borderRadius: '6px', 
                        background: task.status === 'Resolved' ? '#dcfce7' : task.status === 'Rejected' ? '#fffbeb' : '#dbeafe',
                        color: task.status === 'Resolved' ? '#166534' : task.status === 'Rejected' ? '#92400e' : '#1e40af'
                      }}>
                        {task.status?.toUpperCase() || 'PENDING'}
                      </span>
                   </div>
                </div>
              )) : (
                <div style={{ padding: '3rem', textAlign: 'center', color: '#94a3b8' }}>No active missions logged.</div>
              )}
           </div>
        </div>

        {/* RIGHT: UNIT DEPLOYMENT GRID */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
           <div className="widget-card" style={{ background: '#0f172a', padding: '1.5rem', borderRadius: '20px', color: '#f8fafc' }}>
              <h3 style={{ margin: '0 0 1.5rem 0', fontSize: '0.9rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '1px' }}>Unit Deployment</h3>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                 {patrolUnits ? patrolUnits.map(unit => {
                   const isOff = unit.availability === 'break';
                   return (
                     <div key={unit.id} style={{ display: 'flex', alignItems: 'center', gap: '12px', paddingBottom: '1rem', borderBottom: '1px solid #1e293b' }}>
                        <div style={{ position: 'relative' }}>
                          <div style={{ width: '40px', height: '40px', background: '#334155', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                             {isOff ? <Clock size={20} color="#64748b" /> : <Shield size={20} color="#94a3b8" />}
                          </div>
                          <span style={{ 
                            position: 'absolute', bottom: '-2px', right: '-2px', width: '12px', height: '12px', 
                            background: isOff ? '#ef4444' : '#10b981', 
                            border: '2px solid #0f172a', borderRadius: '50%' 
                          }}></span>
                        </div>
                        <div>
                           <p style={{ margin: 0, fontWeight: 700, fontSize: '0.9rem', color: isOff ? '#64748b' : '#f8fafc' }}>{unit.name || `Unit ${unit.id}`}</p>
                           <p style={{ margin: 0, fontSize: '0.75rem', color: isOff ? '#ef4444' : '#64748b' }}>
                             Sector B-4 • {isOff ? 'ON BREAK' : 'ACTIVE'}
                           </p>
                        </div>
                     </div>
                   );
                 }) : (
                   <p style={{ color: '#64748b', fontSize: '0.85rem' }}>Loading unit status...</p>
                 )}
              </div>
           </div>

           <div className="widget-card" style={{ background: '#eff6ff', border: '1px solid #dbeafe', padding: '1.5rem', borderRadius: '20px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '1rem' }}>
                <Clock size={18} color="#2563eb" />
                <h4 style={{ margin: 0, fontSize: '0.9rem', color: '#1e40af' }}>Shift Progress</h4>
              </div>
              <div style={{ height: '8px', background: '#dbeafe', borderRadius: '4px', overflow: 'hidden', marginBottom: '10px' }}>
                 <div style={{ width: '65%', height: '100%', background: '#3b82f6' }}></div>
              </div>
              <p style={{ margin: 0, fontSize: '0.75rem', color: '#64748b' }}>6h 24m remaining in current tactical shift.</p>
           </div>
        </div>

      </div>
    </div>
  );
}

export default StatusSafety;
