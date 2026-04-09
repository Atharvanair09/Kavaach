import React from "react";
import { useNavigate } from "react-router-dom";
import { Shield, Crosshair, ArrowRight, AlertCircle, Folder, Users, CheckCircle, Map, MessageCircle, RefreshCw, ClipboardCheck, Zap, FileText } from "lucide-react";
import "./Home.css";

function Home({ user, role, incidents, patrolUnits }) {
  const navigate = useNavigate();

  // ----------------------------------------------------
  // LOGGED IN VIEW - OVERVIEW DASHBOARD
  // ----------------------------------------------------
  if (user) {
    const activeCases = incidents ? incidents.filter(i => i.status !== "Resolved").length : 0;
    const criticalCases = incidents ? incidents.filter(i => i.priority === "High" && i.status !== "Resolved").length : 0;
    const activePatrols = patrolUnits ? patrolUnits.filter(p => p.status === "Active").length : 0;
    
    return (
      <div className="overview-dashboard">
        <header className="overview-header">
           <div className="welcome-banner">
             <div>
               <h1>Operations Overview</h1>
               <p className="welcome-subtitle">Welcome back, <strong>{user.name}</strong>. System status is nominal for {new Date().toLocaleDateString()}.</p>
             </div>
             <span className={`status-badge role-badge-${role}`}>
               {role.toUpperCase()}
             </span>
           </div>
        </header>

        <section className="stats-grid">
           <div className="card stat-card">
              <div className="stat-icon-wrapper danger"><AlertCircle size={24} /></div>
              <div>
                <span className="stat-label">Critical Alerts</span>
                <span className="stat-value">{criticalCases}</span>
              </div>
           </div>
           <div className="card stat-card">
              <div className="stat-icon-wrapper warning"><Folder size={24} /></div>
              <div>
                <span className="stat-label">Active Cases</span>
                <span className="stat-value">{activeCases}</span>
              </div>
           </div>
           <div className="card stat-card">
              <div className="stat-icon-wrapper primary"><Users size={24} /></div>
              <div>
                <span className="stat-label">Active Patrols</span>
                <span className="stat-value">{activePatrols}</span>
              </div>
           </div>
           <div className="card stat-card">
              <div className="stat-icon-wrapper success"><CheckCircle size={24} /></div>
              <div>
                <span className="stat-label">System Status</span>
                <span className="stat-value" style={{color: '#10b981'}}>Online</span>
              </div>
           </div>
        </section>

        <section className="quick-links-section">
          <h2 className="section-title">Quick Navigation</h2>
          <div className="quick-links-grid">
            {role === "patrol" ? (
              <>
                <button onClick={() => navigate("/patrol/incidents")} className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#eef2ff', color: '#6366f1'}}>
                    <ClipboardCheck size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Incident Handling</h3>
                    <p>View and accept newly assigned incidents from the control room.</p>
                  </div>
                </button>
                <button onClick={() => navigate("/patrol/navigation")} className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#ecfdf5', color: '#10b981'}}>
                    <Map size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Navigation</h3>
                    <p>Get directions and route guidance to the incident location.</p>
                  </div>
                </button>
                <button onClick={() => navigate("/patrol/communication")} className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#fffbeb', color: '#f59e0b'}}>
                    <MessageCircle size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Communication</h3>
                    <p>Contact victim or control room via call/message for coordination.</p>
                  </div>
                </button>
              </>
            ) : (
              <>
                <button onClick={() => navigate("/dashboard")} className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#eef2ff', color: '#6366f1'}}>
                    <Folder size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Case Management</h3>
                    <p>Track reported emergencies and dispatch responders.</p>
                  </div>
                </button>
                <button onClick={() => navigate("/resources")} className="card quick-link-card">
                   <div className="ql-icon-nav" style={{backgroundColor: '#f0fdfa', color: '#2dd4bf'}}>
                     <FileText size={28} />
                   </div>
                   <div className="ql-content">
                     <h3>Resources</h3>
                     <p>Access emergency contacts and guidelines.</p>
                   </div>
                </button>
                <button onClick={() => navigate("/emergency")} className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#fee2e2', color: '#ef4444'}}>
                    <Zap size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Emergency Hub</h3>
                    <p>Broadcast high-priority alerts to the entire network.</p>
                  </div>
                </button>
              </>
            )}
          </div>
        </section>
      </div>
    );
  }

  // ----------------------------------------------------
  // LOGGED OUT VIEW - PUBLIC LANDING PAGE (REDESIGNED)
  // ----------------------------------------------------
  return (
    <div className="landing-page-v2">
      <div className="landing-layout">
        <div className="landing-left">
          <div className="top-pills">
             <span className="pill-badge">SAFETEXT INCIDENT MONITORING</span>
          </div>
          
          <h1 className="hero-title">
            Empowering the<br />
            Fast Response.
          </h1>
          
          <p className="hero-description">
            A unified command and dispatch platform for women's safety. 
            Choose your portal to begin monitoring or responding to emergency calls.
          </p>
          
          <div className="portal-selector-grid">
            {/* Admin Portal Card */}
            <div className="portal-v2-card">
              <div className="p-card-icon">
                <Shield size={24} strokeWidth={2} />
              </div>
              <h3>Official Admin Portal</h3>
              <p>Monitor live dashboards, classify risks, and manage global emergency response.</p>
              <button className="p-btn p-btn-primary" onClick={() => navigate("/auth")}>
                 Admin Access <ArrowRight size={16} />
              </button>
            </div>

            {/* Patrol Portal Card */}
            <div className="portal-v2-card">
              <div className="p-card-icon">
                <Crosshair size={24} strokeWidth={2} />
              </div>
              <h3>Crime Patrol Center</h3>
              <p>Receive assigned patrol tasks, track incident progress, and report completions.</p>
              <button className="p-btn p-btn-outline" onClick={() => navigate("/auth")}>
                 Admin Patrol <ArrowRight size={16} />
              </button>
            </div>
          </div>
        </div>

        <div className="landing-right">
           <div className="hero-visual-container">
             <img src="/logo.jpeg" alt="Safety Monitoring Hero" className="hero-img-neon" />
           </div>
        </div>
      </div>
    </div>
  );
}

export default Home;