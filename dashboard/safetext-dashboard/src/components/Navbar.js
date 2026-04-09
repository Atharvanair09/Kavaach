import React from "react";
import { Link, useLocation } from "react-router-dom";
import { Shield, LayoutDashboard, Folder, MessageSquare, BarChart2, Users, FileText, Bell, ClipboardList, Zap, LogOut, Home, ClipboardCheck, Crosshair, Map, MessageCircle, AlertOctagon, RefreshCw, Clock, AlertTriangle } from "lucide-react";
import "./Navbar.css";

function Navbar({ hasNewIncident, clearNotification, user, role, handleLogout }) {
  const location = useLocation();

  const adminNavLinks = [
    { path: "/", label: "QuickView", icon: LayoutDashboard },
    { path: "/dashboard", label: "Cases", icon: Folder, notify: hasNewIncident },
    { path: "/chat", label: "Chat Monitor", icon: MessageSquare },
    { path: "/analytics", label: "Analytics", icon: BarChart2 },
    { path: "/responders", label: "Responders", icon: Users },
    { path: "/resources", label: "Resources", icon: FileText },
    { path: "/notifications", label: "Notifications", icon: Bell },
    { path: "/audit-log", label: "Audit Log", icon: ClipboardList },
  ];

  const patrolNavLinks = [
    { path: "/patrol/status", label: "Overview", icon: LayoutDashboard },
    { path: "/patrol/navigation", label: "Navigation", icon: Map },
    { path: "/patrol/communication", label: "Communications", icon: MessageSquare },
    { path: "/patrol/stats", label: "My Stats", icon: BarChart2 },
    { path: "/responders", label: "Incident Handling", icon: Users },
  ];

  const navLinks = role === "patrol" ? patrolNavLinks : adminNavLinks;

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <Link to="/" className="brand-logo">
          <div className="shield-icon">
            <Shield size={24} color="white" fill="#3b82f6" strokeWidth={1} />
          </div>
          <div className="brand-text">
            <h2>SafeText</h2>
            <span>NGO DASHBOARD</span>
          </div>
        </Link>
      </div>

      <nav className="sidebar-nav">

        {navLinks.map((link) => (
          <div key={link.path} className="nav-item-container">
             <Link
                to={link.path}
                className={`sidebar-nav-item ${location.pathname === link.path ? "active" : ""}`}
                onClick={link.notify ? clearNotification : undefined}
              >
                <link.icon size={20} className="sidebar-icon" />
                <span>{link.label}</span>
             </Link>
             {link.notify && <span className="sidebar-notification-dot"></span>}
          </div>
        ))}
      </nav>

      <div className="sidebar-footer">
        {user ? (
          <div className="user-section">
            <button className="btn-logout-sidebar" onClick={handleLogout} title="Logout">
              <LogOut size={18} /> <span>Logout</span>
            </button>
          </div>
        ) : (
          <Link to="/auth" className="btn-login-sidebar">
            <span>Sign In</span>
          </Link>
        )}
        <Link to="/emergency" className="emergency-alert-btn">
          <Zap size={18} fill="white" />
          <span>Emergency Alert</span>
        </Link>
      </div>
    </aside>
  );
}

export default Navbar;