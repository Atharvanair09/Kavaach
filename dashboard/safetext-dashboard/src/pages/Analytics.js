import React, { useState, useEffect } from "react";
import { BarChart2, TrendingUp, Users, Clock, Home, AlertOctagon } from "lucide-react";
import { Link } from "react-router-dom";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "../services/firebase";

function Analytics() {
  const [stats, setStats] = useState({ total: 0, resolved: 0, active: 0, highRisk: 0, mediumRisk: 0, lowRisk: 0 });

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "incidents"), (snapshot) => {
      let resolved = 0;
      let active = 0;
      let highRisk = 0;
      let mediumRisk = 0;
      let lowRisk = 0;
      let total = snapshot.docs.length;

      snapshot.docs.forEach(doc => {
        const d = doc.data();
        if (d.status === "Resolved") resolved++;
        else active++;

        // Threat level check
        if (d.threat_level === "HIGH") highRisk++;
        else if (d.threat_level === "MEDIUM") mediumRisk++;
        else lowRisk++;
      });

      setStats({ total, resolved, active, highRisk, mediumRisk, lowRisk });
    });

    return () => unsubscribe();
  }, []);

  const highPct = stats.total ? (stats.highRisk / stats.total) * 100 : 0;
  const mediumPct = stats.total ? (stats.mediumRisk / stats.total) * 100 : 0;
  const lowPct = stats.total ? (stats.lowRisk / stats.total) * 100 : 0;
  return (
    <div className="page-container">
      <div className="card-header flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <BarChart2 className="header-icon primary" />
          <div>
            <h2 style={{fontSize: '1.75rem', fontWeight: 800}}>Platform Analytics</h2>
            <p className="card-subtitle" style={{marginBottom: 0}}>Mock reporting and performance KPIs</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </div>

      <div className="stats-grid" style={{marginTop: '2rem'}}>
        <div className="card stat-card">
          <div className="stat-icon-wrapper danger"><AlertOctagon size={24} /></div>
          <div>
            <span className="stat-label">High Priority Cases</span>
            <span className="stat-value">{stats.highRisk}</span>
          </div>
        </div>
        <div className="card stat-card">
          <div className="stat-icon-wrapper success"><TrendingUp size={24} /></div>
          <div>
            <span className="stat-label">Incidents Resolved</span>
            <span className="stat-value">{stats.resolved}</span>
          </div>
        </div>
        <div className="card stat-card">
          <div className="stat-icon-wrapper warning"><Users size={24} /></div>
          <div>
            <span className="stat-label">Active / Pending</span>
            <span className="stat-value">{stats.active}</span>
          </div>
        </div>
      </div>

      {/* Advanced Threat Classification Chart Section */}
      <div className="card" style={{marginTop: '2rem', padding: '2.5rem'}}>
        <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem'}}>
          <div>
             <h3 style={{fontSize: '1.5rem', marginBottom: '0.5rem', fontWeight: 800}}>Threat Level Classification Ratio</h3>
             <p style={{color: '#64748b', fontSize: '0.95rem'}}>Detailed breakdown of live incidents currently in the system.</p>
          </div>
        </div>

        {stats.total === 0 ? (
           <div style={{padding: '4rem', textAlign: 'center', color: '#64748b', backgroundColor: '#f8fafc', borderRadius: '12px', border: '2px dashed #e2e8f0'}}>
             Waiting for live incident data...
           </div>
        ) : (
          <div style={{display: 'flex', alignItems: 'center', gap: '4rem', flexWrap: 'wrap'}}>
            {/* Elegant Donut Chart */}
            <div style={{position: 'relative'}}>
              <div style={{
                width: '240px',
                height: '240px',
                borderRadius: '50%',
                background: `conic-gradient(
                  #ef4444 0% ${highPct}%,
                  #f59e0b ${highPct}% ${highPct + mediumPct}%,
                  #3b82f6 ${highPct + mediumPct}% 100%
                )`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05)',
                transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)'
              }}>
                <div style={{
                  width: '170px', 
                  height: '170px', 
                  backgroundColor: 'var(--surface)', 
                  borderRadius: '50%',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  boxShadow: 'inset 0 4px 6px rgba(0,0,0,0.05)'
                }}>
                  <h4 style={{fontSize: '3rem', margin: 0, fontWeight: 900, color: 'var(--text-main)', lineHeight: '1'}}>{stats.total}</h4>
                  <span style={{fontSize: '0.9rem', fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.05em', marginTop: '6px'}}>Total</span>
                </div>
              </div>
            </div>

            {/* Detailed Legend Blocks */}
            <div style={{flex: 1, minWidth: '280px'}}>
               <div style={{display: 'flex', flexDirection: 'column', gap: '1.25rem'}}>
                 
                 {/* High Priority Item */}
                 <div style={{display: 'flex', alignItems: 'center', padding: '1.25rem', backgroundColor: '#fef2f2', borderRadius: '12px', borderLeft: '6px solid #ef4444', transition: 'transform 0.2s', cursor: 'default'}} onMouseEnter={(e) => e.currentTarget.style.transform = 'translateX(4px)'} onMouseLeave={(e) => e.currentTarget.style.transform = 'translateX(0)'}>
                   <div style={{width: '14px', height: '14px', borderRadius: '50%', backgroundColor: '#ef4444', marginRight: '1.25rem', flexShrink: 0, boxShadow: '0 0 0 4px #fee2e2'}} />
                   <div style={{flex: 1}}>
                     <h5 style={{margin: 0, fontSize: '1.15rem', fontWeight: 800, color: '#991b1b'}}>High Priority</h5>
                     <span style={{fontSize: '0.9rem', color: '#b91c1c', fontWeight: 500}}>Requires immediate dispatch</span>
                   </div>
                   <div style={{textAlign: 'right'}}>
                     <div style={{fontSize: '1.5rem', fontWeight: 900, color: '#991b1b'}}>{stats.highRisk}</div>
                     <div style={{fontSize: '0.95rem', fontWeight: 800, color: '#ef4444'}}>{highPct.toFixed(1)}%</div>
                   </div>
                 </div>

                 {/* Medium Priority Item */}
                 <div style={{display: 'flex', alignItems: 'center', padding: '1.25rem', backgroundColor: '#fffbeb', borderRadius: '12px', borderLeft: '6px solid #f59e0b', transition: 'transform 0.2s', cursor: 'default'}} onMouseEnter={(e) => e.currentTarget.style.transform = 'translateX(4px)'} onMouseLeave={(e) => e.currentTarget.style.transform = 'translateX(0)'}>
                   <div style={{width: '14px', height: '14px', borderRadius: '50%', backgroundColor: '#f59e0b', marginRight: '1.25rem', flexShrink: 0, boxShadow: '0 0 0 4px #fef3c7'}} />
                   <div style={{flex: 1}}>
                     <h5 style={{margin: 0, fontSize: '1.15rem', fontWeight: 800, color: '#92400e'}}>Medium Priority</h5>
                     <span style={{fontSize: '0.9rem', color: '#b45309', fontWeight: 500}}>Active monitoring & assessment</span>
                   </div>
                   <div style={{textAlign: 'right'}}>
                     <div style={{fontSize: '1.5rem', fontWeight: 900, color: '#92400e'}}>{stats.mediumRisk}</div>
                     <div style={{fontSize: '0.95rem', fontWeight: 800, color: '#f59e0b'}}>{mediumPct.toFixed(1)}%</div>
                   </div>
                 </div>

                 {/* Low Priority Item */}
                 <div style={{display: 'flex', alignItems: 'center', padding: '1.25rem', backgroundColor: '#eff6ff', borderRadius: '12px', borderLeft: '6px solid #3b82f6', transition: 'transform 0.2s', cursor: 'default'}} onMouseEnter={(e) => e.currentTarget.style.transform = 'translateX(4px)'} onMouseLeave={(e) => e.currentTarget.style.transform = 'translateX(0)'}>
                   <div style={{width: '14px', height: '14px', borderRadius: '50%', backgroundColor: '#3b82f6', marginRight: '1.25rem', flexShrink: 0, boxShadow: '0 0 0 4px #dbeafe'}} />
                   <div style={{flex: 1}}>
                     <h5 style={{margin: 0, fontSize: '1.15rem', fontWeight: 800, color: '#1e40af'}}>Low Priority</h5>
                     <span style={{fontSize: '0.9rem', color: '#1d4ed8', fontWeight: 500}}>Standard review queue</span>
                   </div>
                   <div style={{textAlign: 'right'}}>
                     <div style={{fontSize: '1.5rem', fontWeight: 900, color: '#1e40af'}}>{stats.lowRisk}</div>
                     <div style={{fontSize: '0.95rem', fontWeight: 800, color: '#3b82f6'}}>{lowPct.toFixed(1)}%</div>
                   </div>
                 </div>

               </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default Analytics;
