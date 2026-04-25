import React, { useState } from "react";
import { Users, AlertCircle, CheckCircle, Clock, Battery, ArrowRight, Download, ChevronLeft, ChevronRight } from "lucide-react";
import TopNavbar from "../../components/TopNavbar";
import { MapContainer, TileLayer, Marker } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix for default Leaflet icon issue
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

function StatusSafety({ incidents = [], patrolUnits = [], user, role }) {
  const [currentIndex, setCurrentIndex] = useState(0);

  // Identify the current patrol unit based on user email
  const myUnitId = patrolUnits.find(p => p.email === user?.email)?.id;

  // Filter for active critical incidents (SOS or High Priority) assigned to THIS responder
  const criticalIncidents = incidents.filter(i => 
    (i.status === "Pending" || i.status === "In Progress") && 
    (i.category === "Emergency" || i.category === "Missed Check-in" || i.priority?.toLowerCase() === "high") &&
    (i.assignedTo === myUnitId)
  );

  const currentIncident = criticalIncidents[currentIndex];
  const totalIncidents = criticalIncidents.length;

  const handleNext = () => {
    if (totalIncidents <= 1) return;
    setCurrentIndex((prev) => (prev + 1) % totalIncidents);
  };

  const handlePrev = () => {
    if (totalIncidents <= 1) return;
    setCurrentIndex((prev) => (prev - 1 + totalIncidents) % totalIncidents);
  };

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
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>{incidents.filter(i => i.status === "Resolved").length}</h2>
              <span style={{ fontSize: '0.75rem', color: '#cbd5e1', fontWeight: 600 }}>Active Session</span>
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
              <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Active Responders</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px' }}>
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>{patrolUnits.filter(p => p.availability === 'active').length}</h2>
              <span style={{ fontSize: '0.75rem', color: '#10b981', fontWeight: 700 }}>Online</span>
            </div>
          </div>

          {/* Card 4: CURRENT ALERTS */}
          <div style={{ 
            background: '#ffffff', 
            borderRadius: '28px', 
            padding: '1.75rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.04)',
            borderBottom: '5px solid #ef4444'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: '#fef2f2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ef4444' }}>
                <AlertCircle size={20} strokeWidth={2.5} />
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.8px' }}>Critical Alerts</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '10px' }}>
              <h2 style={{ fontSize: '2.2rem', fontWeight: 900, color: '#0f172a', margin: 0 }}>{totalIncidents}</h2>
              <span style={{ fontSize: '0.75rem', color: '#ef4444', fontWeight: 700 }}>Priority 1</span>
            </div>
          </div>
        </div>

        {/* Main Dashboard Grid */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: '1fr 340px', 
          gap: '2rem',
          marginBottom: '2.5rem',
          alignItems: 'start'
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
            {currentIncident ? (
              <>
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
                          background: currentIncident.priority === "High" ? '#991b1b' : '#3b82f6', 
                          color: 'white', 
                          fontSize: '10px', 
                          fontWeight: 800, 
                          padding: '2px 8px', 
                          borderRadius: '6px',
                          textTransform: 'uppercase'
                        }}>{currentIncident.priority === "High" ? 'High Severity' : 'Critical Alert'}</span>
                        <span style={{ color: '#94a3b8', fontSize: '12px', fontWeight: 500 }}>ID: #{currentIncident.id.substring(0, 8).toUpperCase()}</span>
                      </div>
                      <h3 style={{ fontSize: '1.25rem', fontWeight: 750, color: '#0f172a' }}>{currentIncident.text || "Emergency Triggered"}</h3>
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ color: '#94a3b8', fontSize: '11px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '4px' }}>Reported At</div>
                    <div style={{ color: '#2563eb', fontSize: '1.1rem', fontWeight: 800 }}>{currentIncident.timestamp}</div>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr' }}>
                  {/* Map visual */}
                  <div style={{ position: 'relative', overflow: 'hidden', height: '400px' }}>
                    <MapContainer 
                      center={[currentIncident.lat || 19.076, currentIncident.lng || 72.877]} 
                      zoom={15} 
                      scrollWheelZoom={false}
                      style={{ height: '100%', width: '100%' }}
                    >
                      <TileLayer
                        url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}{r}.png"
                      />
                      <Marker position={[currentIncident.lat, currentIncident.lng]} />
                    </MapContainer>
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
                      boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)',
                      zIndex: 1000
                    }}>
                      <span className="pulse-red" style={{ width: '8px', height: '8px', background: '#3b82f6', borderRadius: '50%', boxShadow: '0 0 0 4px rgba(59, 130, 246, 0.2)' }}></span>
                      <div style={{ textTransform: 'uppercase', fontSize: '10px', fontWeight: 800, color: '#1e40af' }}>Live Tracking Active</div>
                    </div>
                  </div>

                  {/* User Profile */}
                  <div style={{ padding: '1.5rem 2.5rem', display: 'flex', flexDirection: 'column', borderLeft: '1px solid #f1f5f9' }}>
                    <div style={{ color: '#94a3b8', fontSize: '11px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '1rem' }}>Incident Details</div>
                    
                    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '1.5rem' }}>
                      <div style={{ width: '48px', height: '48px', borderRadius: '50%', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#94a3b8' }}>
                        <Users size={24} />
                      </div>
                      <div>
                        <h4 style={{ fontSize: '1rem', fontWeight: 750, color: '#0f172a', marginBottom: '2px' }}>{currentIncident.senderName || "User Anonymous"}</h4>
                        <p style={{ color: '#64748b', fontSize: '0.85rem' }}>{currentIncident.senderEmail || "Verified User"}</p>
                      </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Coordinates</span>
                        <span style={{ color: '#0f172a', fontWeight: 700, fontSize: '0.9rem' }}>{currentIncident.lat?.toFixed(4)}, {currentIncident.lng?.toFixed(4)}</span>
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Status</span>
                        <span style={{ color: '#ef4444', fontWeight: 700, textTransform: 'uppercase', fontSize: '0.9rem' }}>{currentIncident.status}</span>
                      </div>
                    </div>

                    <button style={{ 
                      background: '#0561f0', 
                      color: 'white', 
                      padding: '0.8rem', 
                      borderRadius: '12px', 
                      border: 'none', 
                      fontWeight: 700, 
                      display: 'flex', 
                      alignItems: 'center', 
                      justifyContent: 'center', 
                      gap: '8px',
                      cursor: 'pointer',
                      fontSize: '0.9rem',
                      boxShadow: '0 8px 12px -3px rgba(5, 97, 240, 0.2)',
                      marginTop: '1rem'
                    }}>
                      View Full Details <ArrowRight size={16} />
                    </button>
                    
                    {/* High-Fidelity Pagination Bar - Always Visible */}
                    <div style={{ 
                      display: 'flex', 
                      alignItems: 'center', 
                      justifyContent: 'center', 
                      gap: '0.5rem', 
                      marginTop: '1.5rem',
                      paddingTop: '1rem',
                      borderTop: '1px solid #f1f5f9',
                      opacity: totalIncidents <= 1 ? 0.6 : 1,
                      pointerEvents: totalIncidents <= 1 ? 'none' : 'auto'
                    }}>
                        <button 
                          onClick={handlePrev}
                          disabled={currentIndex === 0}
                          style={{ 
                            background: 'none', 
                            border: 'none', 
                            cursor: 'pointer', 
                            color: '#94a3b8',
                            display: 'flex',
                            alignItems: 'center',
                            padding: '4px'
                          }}
                        >
                          <ChevronLeft size={18} />
                        </button>
                        
                        <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
                          {(() => {
                            const pages = [];
                            if (totalIncidents <= 5) {
                              for (let i = 0; i < totalIncidents; i++) pages.push(i);
                            } else {
                              // Match the image style: 1 2 3 4 ... LastFew
                              if (currentIndex < 3) {
                                pages.push(0, 1, 2, 3, '...', totalIncidents - 1);
                              } else if (currentIndex > totalIncidents - 4) {
                                pages.push(0, '...', totalIncidents - 4, totalIncidents - 3, totalIncidents - 2, totalIncidents - 1);
                              } else {
                                pages.push(0, '...', currentIndex, '...', totalIncidents - 1);
                              }
                            }

                            return pages.map((p, idx) => (
                              p === '...' ? (
                                <span key={`sep-${idx}`} style={{ color: '#94a3b8', fontSize: '0.8rem', padding: '0 4px' }}>...</span>
                              ) : (
                                <button
                                  key={p}
                                  onClick={() => setCurrentIndex(p)}
                                  style={{
                                    width: '32px',
                                    height: '32px',
                                    borderRadius: '10px',
                                    border: 'none',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '0.85rem',
                                    fontWeight: 700,
                                    cursor: 'pointer',
                                    transition: 'all 0.2s ease',
                                    background: currentIndex === p ? '#2563eb' : '#f1f5f9',
                                    color: currentIndex === p ? 'white' : '#64748b',
                                    boxShadow: currentIndex === p ? '0 4px 10px rgba(37, 99, 235, 0.25)' : 'none'
                                  }}
                                >
                                  {p + 1}
                                </button>
                              )
                            ));
                          })()}
                        </div>

                        <button 
                          onClick={handleNext}
                          disabled={currentIndex === totalIncidents - 1}
                          style={{ 
                            background: 'none', 
                            border: 'none', 
                            cursor: 'pointer', 
                            color: '#94a3b8',
                            display: 'flex',
                            alignItems: 'center',
                            padding: '4px'
                          }}
                        >
                          <ChevronRight size={18} />
                        </button>
                      </div>
                  </div>
                </div>
              </>
            ) : (
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '4rem', textAlign: 'center' }}>
                <CheckCircle size={64} style={{ color: '#10b981', marginBottom: '1.5rem' }} />
                <h3 style={{ fontSize: '1.5rem', fontWeight: 750, color: '#0f172a' }}>No Critical Alerts</h3>
                <p style={{ color:   '#64748b', fontSize: '1rem', maxWidth: '400px' }}>Total sector safety achieved. Monitoring standby active.</p>
              </div>
            )}
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
              <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', textTransform: 'uppercase', letterSpacing: '1px' }}>Feed Status</h3>
              <div style={{ width: '8px', height: '8px', background: '#0561f0', borderRadius: '50%' }}></div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', flex: 1 }}>
              {incidents.slice(0, 4).map((alert, i) => (
                <div key={i} style={{ 
                  padding: '1.25rem', 
                  borderLeft: `4px solid ${alert.status === 'Resolved' ? '#10b981' : '#3b82f6'}`,
                  background: '#f8fafc',
                  borderRadius: '0 16px 16px 0',
                  position: 'relative'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                    <span style={{ fontSize: '10px', color: '#94a3b8', fontWeight: 600 }}>{alert.timestamp}</span>
                    <span style={{ 
                      fontSize: '9px', 
                      fontWeight: 800, 
                      color: alert.status === 'Resolved' ? '#10b981' : '#3b82f6', 
                      background: `${alert.status === 'Resolved' ? '#10b981' : '#3b82f6'}15`,
                      padding: '2px 6px',
                      borderRadius: '4px'
                    }}>{alert.status === 'Resolved' ? 'RESOLVED' : 'ACTIVE'}</span>
                  </div>
                  <h4 style={{ fontSize: '0.9rem', fontWeight: 750, color: '#0f172a', marginBottom: '4px' }}>{alert.text}</h4>
                  <p style={{ fontSize: '0.8rem', color: '#64748b', lineHeight: 1.4 }}>ID: #{alert.id.substring(0, 4)}</p>
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
