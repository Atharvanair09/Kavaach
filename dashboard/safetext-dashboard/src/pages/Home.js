import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { ShieldCheck, Crosshair, ArrowRight, LayoutDashboard, Users, Folder, MessageSquare, AlertCircle, FileText, Bell, Zap, CheckCircle, Map, MessageCircle, RefreshCw, ClipboardCheck } from "lucide-react";

function Home({ user, role, handleLogout, incidents, patrolUnits }) {
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
               <h1>QuickView</h1>
               <p className="welcome-subtitle">Welcome back, <strong>{user.name}</strong>. Here's your summary for {new Date().toLocaleDateString()}.</p>
             </div>
             <span className={`status-badge status-in-progress role-badge`}>
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
                <Link to="/dashboard" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#eef2ff', color: '#6366f1'}}>
                    <ClipboardCheck size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Assigned Tasks</h3>
                    <p>View and accept newly assigned incidents from the control room.</p>
                  </div>
                </Link>
                <Link to="/patrol/mission" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#fef2f2', color: '#ef4444'}}>
                    <Crosshair size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Active Mission</h3>
                    <p>Track and manage the current case being handled in real-time.</p>
                  </div>
                </Link>
                <Link to="/patrol/navigation" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#ecfdf5', color: '#10b981'}}>
                    <Map size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Navigation</h3>
                    <p>Get directions and route guidance to the incident location.</p>
                  </div>
                </Link>
                <Link to="/patrol/communication" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#fffbeb', color: '#f59e0b'}}>
                    <MessageCircle size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Communication</h3>
                    <p>Contact victim or control room via call/message for coordination.</p>
                  </div>
                </Link>
                <Link to="/patrol/alerts" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#fdf4ff', color: '#d946ef'}}>
                    <AlertCircle size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Emergency Alert</h3>
                    <p>Receive instant high-priority alerts requiring immediate response.</p>
                  </div>
                </Link>
                <Link to="/patrol/status" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#f0fdf4', color: '#22c55e'}}>
                    <RefreshCw size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Status Update</h3>
                    <p>Update case progress (accepted, on the way, reached, resolved).</p>
                  </div>
                </Link>
              </>
            ) : (
              <>
                <Link to="/dashboard" className="card quick-link-card">
                  <div className="ql-icon-nav" style={{backgroundColor: '#eef2ff', color: '#6366f1'}}>
                    <Folder size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Case Management</h3>
                    <p>Track reported emergencies and dispatch responders.</p>
                  </div>
                </Link>
                <Link to="/resources" className="card quick-link-card">
                   <div className="ql-icon-nav" style={{backgroundColor: '#f0fdfa', color: '#2dd4bf'}}>
                     <FileText size={28} />
                   </div>
                   <div className="ql-content">
                     <h3>Resources & Directory</h3>
                     <p>Access emergency contacts, guidelines, and manuals.</p>
                   </div>
                </Link>
                <Link to="/emergency" className="card quick-link-card emergency-link">
                  <div className="ql-icon-nav" style={{backgroundColor: '#fee2e2', color: '#ef4444'}}>
                    <Zap size={28} />
                  </div>
                  <div className="ql-content">
                    <h3>Emergency Hub</h3>
                    <p>Broadcast high-priority alerts to the entire network.</p>
                  </div>
                </Link>
              </>
            )}
          </div>
        </section>
      </div>
    );
  }

  // ----------------------------------------------------
  // LOGGED OUT VIEW - PUBLIC LANDING PAGE
  // ----------------------------------------------------
  return (
    <div className="home-page portal-view">
      <section className="hero portal-hero">
        <div className="hero-content">
          <div className="portal-badge">SafeText Incident Monitoring</div>
          <h1>Empowering the Fast Response.</h1>
          <p className="hero-subtitle">
            A unified command and dispatch platform for women's safety.
            Choose your portal to begin monitoring or responding to emergency calls.
          </p>

          <div className="portal-options">
            <div className="card portal-card">
              <ShieldCheck className="portal-card-icon primary" size={40} />
              <h3>Official Admin Portal</h3>
              <p>Monitor live dashboards, classify risks, and manage global emergency response.</p>
              <button
                className="btn btn-primary btn-block"
                onClick={() => navigate("/auth")}
              >
                Admin Access <ArrowRight size={18} />
              </button>
            </div>
            <div className="card portal-card">
              <Crosshair className="portal-card-icon secondary" size={40} />
              <h3>Crime Patrol Center</h3>
              <p>Receive assigned patrol tasks, track incident progress, and report completions.</p>
              <button
                className="btn btn-outline btn-block"
                onClick={() => navigate("/auth")}
              >
                Join Patrol <ArrowRight size={18} />
              </button>
            </div>
          </div>
        </div>

        <div className="hero-image hide-on-mobile">
          <img src="/safety_hero.png" alt="Safety Illustration" className="floating-img" />
        </div>
      </section>

      <section className="portal-stats">
        <div className="p-stat">
          <strong>24/7</strong>
          <span> Live Monitoring</span>
        </div>
        <div className="p-stat">
          <strong>Instant</strong>
          <span> Patrol Dispatch</span>
        </div>
        <div className="p-stat">
          <strong>Encrypted</strong>
          <span> Secure Reporting</span>
        </div>
      </section>
    </div>
  );
}

export default Home;