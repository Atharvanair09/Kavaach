import React, { useState } from "react";
import { Users, MapPin, ClipboardSignature, Home, ChevronDown, CheckCircle, Clock } from "lucide-react";
import { Link } from "react-router-dom";


function Responders({ patrolUnits, incidents, assignPatrol, addManualIncident, updateStatus, updateUnitStatus, role }) {
  const [manualInputs, setManualInputs] = useState({});
  const [recentActions, setRecentActions] = useState({}); // { taskId: { action: 'accepted'|'rejected', unitId: string } }

  const units = patrolUnits || [];

  const handleManualAssign = async (unitId) => {
    const text = manualInputs[unitId];
    if (!text || text.trim() === "") return;
    
    await addManualIncident(unitId, text);
    // Clear input
    setManualInputs(prev => ({ ...prev, [unitId]: "" }));
  };

  const handleInputChange = (unitId, value) => {
    setManualInputs(prev => ({ ...prev, [unitId]: value }));
  };

  const handlePatrolAction = async (unit, taskId, action) => {
    // Prevent actions if on break
    if (unit.availability === 'break') return;

    // 1. Set local feedback state with unit scoping
    setRecentActions(prev => ({ ...prev, [taskId]: { action, unitId: unit.id } }));
    
    // 2. Perform the update
    if (action === 'accepted') {
      await updateStatus(taskId, "In Progress");
    } else {
      await updateStatus(taskId, "Pending"); // Rejects the assignment
    }

    // Optional: clear the 'rejected' feedback after a short delay
    if (action === 'rejected') {
      setTimeout(() => {
        setRecentActions(prev => {
          const updated = { ...prev };
          delete updated[taskId];
          return updated;
          });
      }, 2500);
    }
  };

  const handleStatusChange = (unitId, status) => {
    updateUnitStatus(unitId, status);
  };

  return (
    <div className="page-container">
      <style>{`
        .action-feedback {
          animation: slideUp 0.3s ease-out forwards;
        }
        @keyframes slideUp {
          from { opacity: 0; transform: translateY(5px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .status-select {
          padding: 4px 8px;
          border-radius: 8px;
          border: 1px solid #e2e8f0;
          font-size: 0.75rem;
          font-weight: 700;
          background: #f8fafc;
          color: #475569;
          cursor: pointer;
          outline: none;
        }
        .status-select:hover { border-color: #cbd5e1; }
        .on-break-overlay {
          color: #94a3b8;
          font-style: italic;
          font-size: 0.8rem;
          margin-top: 10px;
          display: flex;
          align-items: center;
          gap: 6px;
        }
      `}</style>
      <div className="card-header flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <Users className="header-icon primary" />
          <div>
            <h2 style={{fontSize: '1.75rem', fontWeight: 800}}>
              {role === 'admin' ? "Responders Directory" : "Incident Handling"}
            </h2>
            <p className="card-subtitle" style={{marginBottom: 0}}>
              {role === 'admin' 
                ? "Manage patrol units and dispatch teams" 
                : "View all the assigned/incoming cases for your unit"}
            </p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '2rem', marginTop: '2rem' }}>
        {units.map(unit => {
          const isPatrol = role === 'patrol';
          const isBreak = unit.availability === 'break';

          // Filter cases assigned to this unit OR cases that were just rejected by THIS SPECIFIC unit
          const unitTasks = incidents?.filter(i => 
            (i.assignedTo === unit.id && i.status !== "Resolved") || 
            (recentActions[i.id]?.unitId === unit.id && recentActions[i.id]?.action === 'rejected')
          ) || [];
          
          return (
            <div key={unit.id} className="card" style={{padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.25rem', opacity: isBreak ? 0.75 : 1, transition: 'all 0.3s'}}>
               <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '1rem', flexWrap: 'wrap'}}>
                  <div style={{display: 'flex', alignItems: 'center', gap: '10px'}}>
                    <h3 style={{margin: 0, fontSize: '1.3rem'}}>{unit.name}</h3>
                    {isPatrol && (
                      <select 
                        className="status-select"
                        value={unit.availability || 'active'}
                        onChange={(e) => handleStatusChange(unit.id, e.target.value)}
                      >
                        <option value="active">CURRENTLY ACTIVE</option>
                        <option value="break">ON-BREAK</option>
                      </select>
                    )}
                  </div>
                  <span style={{
                     padding: '4px 12px', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 800,
                     backgroundColor: isBreak ? '#fee2e2' : (unit.status === 'Active' ? '#dcfce7' : '#f1f5f9'),
                     color: isBreak ? '#dc2626' : (unit.status === 'Active' ? '#16a34a' : '#64748b'),
                     textTransform: 'uppercase'
                  }}>
                    {isBreak ? 'ON BREAK' : unit.status}
                  </span>
               </div>
               
               <div style={{display: 'flex', alignItems: 'center', gap: '8px', color: '#64748b'}}>
                 <MapPin size={16} />
                 <span style={{fontSize: '0.95rem'}}>{unit.location}</span>
               </div>

               {/* --- ADMIN VIEW: TEXTBOX + ASSIGN --- */}
               {role === 'admin' && (
                 <div style={{marginTop: '0.5rem', display: 'flex', flexDirection: 'column', gap: '0.75rem', padding: '1rem', backgroundColor: isBreak ? '#f1f5f9' : '#f8fafc', borderRadius: '12px', border: '1px solid #e2e8f0', filter: isBreak ? 'grayscale(1)' : 'none'}}>
                    <label style={{fontSize: '0.85rem', fontWeight: 700, color: '#475569'}}>Manual Task Entry</label>
                    <textarea 
                      placeholder={isBreak ? "Unit is currently on break..." : "Type specific case details..."}
                      style={{
                        padding: '0.75rem', borderRadius: '8px', border: '1px solid #cbd5e1', 
                        fontSize: '0.9rem', resize: 'none', height: '80px', fontFamily: 'inherit'
                      }}
                      value={manualInputs[unit.id] || ""}
                      onChange={(e) => handleInputChange(unit.id, e.target.value)}
                      disabled={isBreak}
                    />
                    <button 
                      className="btn btn-primary" 
                      style={{width: '100%', padding: '0.75rem', display: 'flex', gap: '8px', justifyContent: 'center', alignItems: 'center'}}
                      onClick={() => handleManualAssign(unit.id)}
                      disabled={isBreak || !manualInputs[unit.id] || manualInputs[unit.id].trim() === ""}
                    >
                      {isBreak ? (
                        <>
                          <Clock size={18} /> Unit on Break
                        </>
                      ) : (
                        <>
                          <ClipboardSignature size={18} /> Assign Case
                        </>
                      )}
                    </button>
                    {isBreak && (
                      <p style={{margin: '5px 0 0 0', fontSize: '0.7rem', color: '#dc2626', fontWeight: 700, textAlign: 'center'}}>
                        LOCK ENABLED: Wait for unit to resume active status.
                      </p>
                    )}
                 </div>
               )}

               {/* --- PATROL VIEW: ASSIGNED CASES + ACCEPT/REJECT --- */}
               {isPatrol && (
                 <div style={{marginTop: '0.5rem'}}>
                    <h4 style={{fontSize: '0.85rem', fontWeight: 800, color: isBreak ? '#94a3b8' : '#3b82f6', marginBottom: '1rem', textTransform: 'uppercase', letterSpacing: '0.5px'}}>
                      Select case from below
                    </h4>
                    
                    <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
                       {unitTasks.length > 0 ? (
                         unitTasks.map(task => {
                           const actionData = recentActions[task.id];
                           const isMyTask = task.assignedTo === unit.id;

                           let actionTaken = null;
                           if (actionData?.unitId === unit.id) {
                             actionTaken = actionData.action;
                           } else if (isMyTask && task.status === 'In Progress') {
                             actionTaken = 'accepted';
                           } else if (isMyTask && task.status === 'Rejected') {
                             actionTaken = 'rejected';
                           }
                           
                           return (
                             <div key={task.id} style={{padding: '1rem', borderRadius: '12px', border: '1px solid #e2e8f0', backgroundColor: '#fff', boxShadow: '0 2px 4px rgba(0,0,0,0.02)', opacity: isBreak ? 0.6 : 1}}>
                                <p style={{margin: '0 0 10px 0', fontSize: '0.95rem', fontWeight: 500, color: '#1e293b'}}>
                                  {task.text || task.message}
                                </p>
                                <div style={{display: 'flex', gap: '0.5rem', marginTop: '1rem'}}>
                                   <button 
                                     className="btn btn-sm" 
                                     style={{
                                       flex: 1, border: 'none', fontWeight: 700,
                                       backgroundColor: actionTaken === 'rejected' ? '#f1f5f9' : '#dcfce7',
                                       color: actionTaken === 'rejected' ? '#94a3b8' : '#16a34a',
                                       transition: 'all 0.2s'
                                     }}
                                     onClick={() => handlePatrolAction(unit, task.id, 'accepted')}
                                     disabled={!!actionTaken || isBreak}
                                   >
                                     Accept
                                   </button>
                                   <button 
                                     className="btn btn-sm" 
                                     style={{
                                       flex: 1, border: 'none', fontWeight: 700,
                                       backgroundColor: actionTaken === 'accepted' ? '#f1f5f9' : '#fee2e2',
                                       color: actionTaken === 'accepted' ? '#94a3b8' : '#dc2626',
                                       transition: 'all 0.2s'
                                     }}
                                     onClick={() => handlePatrolAction(unit, task.id, 'rejected')}
                                     disabled={!!actionTaken || isBreak}
                                   >
                                     Reject
                                   </button>
                                </div>
                                {actionTaken && (
                                   <p className="action-feedback" style={{
                                     textAlign: 'center', marginTop: '10px', marginBottom: 0, 
                                     fontSize: '0.85rem', fontWeight: 800,
                                     color: actionTaken === 'accepted' ? '#16a34a' : '#dc2626'
                                   }}>
                                     Case {actionTaken === 'accepted' ? 'Accepted' : 'Rejected'}
                                   </p>
                                )}
                             </div>
                           );
                         })
                       ) : (
                         <div style={{padding: '1rem', textAlign: 'center', color: '#94a3b8', fontSize: '0.85rem', border: '1px dashed #cbd5e1', borderRadius: '8px', opacity: 0.7}}>
                           No active cases assigned.
                         </div>
                       )}
                    </div>
                    {isBreak && (
                      <div className="on-break-overlay">
                        <Clock size={14} /> Currently on break. Resume status to handle cases.
                      </div>
                    )}
                 </div>
               )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default Responders;
