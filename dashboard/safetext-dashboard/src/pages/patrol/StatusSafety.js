import React from "react";
import { Users, AlertCircle, CheckCircle, Clock, Battery, ArrowRight, Download } from "lucide-react";
import TopNavbar from "../../components/TopNavbar";

// Reference the generated image
const TACTICAL_MAP = "/tactical_map_ui_1777049482765.png";

function StatusSafety({ incidents, patrolUnits, user, role }) {
  return (
    <div className="patrol-page-container tactical" style={{ 
      background: '#f8fafc', 
      minHeight: '100vh', 
      padding: 0,
      fontFamily: "'Inter', sans-serif"
    }}>
      {/* Top Navigation */}
      <TopNavbar user={user} role={role} />

      <div style={{ padding: '0rem 1rem 1rem 1rem', maxWidth: '1400px', margin: '0 auto' }}>
        {/* Page Header */}
        <div className="dashboard-header-row" style={{ marginBottom: '1.5rem' }}>
          <div className="header-left">
            <h1 style={{ fontSize: '1.85rem' }}>Operational Overview</h1>
            <p>Real-time surveillance for Sector Alpha Deployment.</p>
          </div>
        </div>

        {/* Top Stat Cards */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(4, 1fr)', 
          gap: '1.5rem',
          marginBottom: '2.5rem'
        }}>
          {/* Card 1: AVG RESPONSE TIME */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '28px', 
            padding: '1.75rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.04)',
            borderBottom: '5px solid #2563eb',
            position: 'relative'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb' }}>
                <Clock size={20} strokeWidth={2.5} />
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Avg Response Time</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px' }}>
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>2.4m</h2>
              <span style={{ fontSize: '0.75rem', color: '#10b981', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}>
                &darr; 12% today
              </span>
            </div>
          </div>

          {/* Card 2: CASES RESOLVED */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '28px', 
            padding: '1.75rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.04)',
            borderBottom: '5px solid #2563eb'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb' }}>
                <CheckCircle size={20} strokeWidth={2.5} />
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Cases Resolved</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px' }}>
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>48</h2>
              <span style={{ fontSize: '0.75rem', color: '#cbd5e1', fontWeight: 600 }}>Target: 50</span>
            </div>
          </div>

          {/* Card 3: ACTIVE MEMBERS */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '28px', 
            padding: '1.75rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.04)',
            borderBottom: '5px solid #2563eb'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb' }}>
                <Users size={20} strokeWidth={2.5} />
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Active Members</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px' }}>
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>12</h2>
              <span style={{ fontSize: '0.75rem', color: '#10b981', fontWeight: 700 }}>All Online</span>
            </div>
          </div>

          {/* Card 4: SIGNAL STATUS */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '28px', 
            padding: '1.75rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.04)',
            borderBottom: '5px solid #2563eb'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#2563eb' }}>
                <Battery size={20} strokeWidth={2.5} />
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Signal Status</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px' }}>
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>100%</h2>
              <span style={{ fontSize: '0.75rem', color: '#2563eb', fontWeight: 700 }}>Encrypted L5</span>
            </div>
          </div>
        </div>

        {/* Main Dashboard Grid */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: '1fr 340px', 
          gap: '2rem',
          marginBottom: '2.5rem'
        }}>
          
          {/* Left Side: SOS Card */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '32px', 
            overflow: 'hidden',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.05)',
            display: 'flex',
            flexDirection: 'column'
          }}>
            {/* SOS Header */}
            <div style={{ 
              padding: '1.5rem 2rem', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'space-between',
              borderBottom: '1px solid #f1f5f9'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                <div style={{ 
                  background: '#fef2f2', 
                  color: '#ef4444', 
                  width: '48px', 
                  height: '48px', 
                  borderRadius: '14px', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center' 
                }}>
                  <AlertCircle size={24} strokeWidth={2.5} />
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '4px' }}>
                    <span style={{ 
                      background: '#991b1b', 
                      color: 'white', 
                      fontSize: '10px', 
                      fontWeight: 800, 
                      padding: '2px 8px', 
                      borderRadius: '6px',
                      textTransform: 'uppercase'
                    }}>High Severity</span>
                    <span style={{ color: '#94a3b8', fontSize: '12px', fontWeight: 500 }}>ID: #UX-294-88</span>
                  </div>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 750, color: '#0f172a' }}>SOS Triggered: Silent Mode</h3>
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ color: '#94a3b8', fontSize: '11px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '4px' }}>Duration</div>
                <div style={{ color: '#2563eb', fontSize: '1.1rem', fontWeight: 800 }}>04:12:09</div>
              </div>
            </div>

            {/* Tracking Content */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', flex: 1 }}>
              {/* Map visual */}
              <div style={{ position: 'relative', overflow: 'hidden', height: '400px' }}>
                <img 
                  src={TACTICAL_MAP} 
                  alt="Tactical Map" 
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
                <div style={{ 
                  position: 'absolute', 
                  top: '1.5rem', 
                  left: '1.5rem',
                  background: 'rgba(255, 255, 255, 0.9)',
                  backdropFilter: 'blur(8px)',
                  padding: '8px 16px',
                  borderRadius: '20px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)'
                }}>
                  <span style={{ width: '8px', height: '8px', background: '#3b82f6', borderRadius: '50%', boxShadow: '0 0 0 4px rgba(59, 130, 246, 0.2)' }}></span>
                  <div style={{ textTransform: 'uppercase', fontSize: '10px', fontWeight: 800, color: '#1e40af' }}>Live Tracking</div>
                  <div style={{ color: '#94a3b8', fontSize: '10px', marginLeft: '4px' }}>Signal: Encrypted (98%)</div>
                </div>
              </div>

              {/* User Profile */}
              <div style={{ padding: '2.5rem', display: 'flex', flexDirection: 'column', borderLeft: '1px solid #f1f5f9' }}>
                <div style={{ color: '#94a3b8', fontSize: '12px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '1.5rem' }}>User Profile</div>
                
                <div style={{ display: 'flex', gap: '1.25rem', alignItems: 'center', marginBottom: '2.5rem' }}>
                  <div style={{ width: '56px', height: '56px', borderRadius: '50%', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
                    <Users size={28} />
                  </div>
                  <div>
                    <h4 style={{ fontSize: '1.1rem', fontWeight: 750, color: '#0f172a', marginBottom: '2px' }}>User Anonymous</h4>
                    <p style={{ color: '#64748b', fontSize: '0.9rem' }}>Verified Safeguard Account</p>
                  </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Distance</span>
                    <span style={{ color: '#0f172a', fontWeight: 700 }}>0.8 miles</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Battery</span>
                    <span style={{ color: '#ef4444', fontWeight: 700 }}>12%</span>
                  </div>
                </div>

                <button style={{ 
                  background: '#0561f0', 
                  color: 'white', 
                  padding: '1rem', 
                  borderRadius: '16px', 
                  border: 'none', 
                  fontWeight: 700, 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  gap: '10px',
                  cursor: 'pointer',
                  boxShadow: '0 10px 15px -3px rgba(5, 97, 240, 0.3)'
                }}>
                  View Full Details <ArrowRight size={18} />
                </button>
              </div>
            </div>
          </div>

          {/* Right Side: Nearby Alerts */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '32px', 
            padding: '2rem 1.5rem',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.05)',
            display: 'flex',
            flexDirection: 'column'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', textTransform: 'uppercase', letterSpacing: '1px' }}>Nearby Alerts</h3>
              <div style={{ width: '8px', height: '8px', background: '#0561f0', borderRadius: '50%' }}></div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', flex: 1 }}>
              {[
                { time: "14:05:22", type: "SEVERE", title: "Unusual Route Deviation", desc: "User ID #990 has deviated from their commute pattern by 2.5 miles.", color: "#ef4444" },
                { time: "13:58:10", type: "MEDIUM", title: "Check-in Expired", desc: "Expected check-in for Agent Bravo was missed. Pinging last location.", color: "#3b82f6" },
                { time: "13:42:00", type: "INFO", title: "Unit Deployment", desc: "Field Unit 07 has reached the extraction zone.", color: "#94a3b8" },
                { time: "13:30:15", type: "SEVERE", title: "Vibration Pattern Alert", desc: "High-frequency device impact detected for user #012.", color: "#ef4444" },
              ].map((alert, i) => (
                <div key={i} style={{ 
                  padding: '1.25rem', 
                  borderLeft: `4px solid ${alert.color}`,
                  background: '#f8fafc',
                  borderRadius: '0 16px 16px 0',
                  position: 'relative'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <span style={{ fontSize: '10px', color: '#94a3b8', fontWeight: 600 }}>{alert.time}</span>
                    <span style={{ 
                      fontSize: '9px', 
                      fontWeight: 800, 
                      color: alert.color, 
                      background: `${alert.color}15`,
                      padding: '2px 6px',
                      borderRadius: '4px'
                    }}>{alert.type}</span>
                  </div>
                  <h4 style={{ fontSize: '0.9rem', fontWeight: 750, color: '#0f172a', marginBottom: '4px' }}>{alert.title}</h4>
                  <p style={{ fontSize: '0.8rem', color: '#64748b', lineHeight: 1.4 }}>{alert.desc}</p>
                </div>
              ))}
            </div>

            <button style={{ 
              background: 'transparent', 
              border: 'none', 
              color: '#0561f0', 
              fontWeight: 700, 
              fontSize: '0.85rem', 
              marginTop: '1.5rem',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px'
            }}>
              <Download size={16} /> Download Feed History
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}

export default StatusSafety;
