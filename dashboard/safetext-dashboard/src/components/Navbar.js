import React from "react";
import { Link, useLocation } from "react-router-dom";
import { Shield, LayoutDashboard, Folder, MessageSquare, BarChart2, Users, FileText, Bell, ClipboardList, Zap, LogOut, Home, ClipboardCheck, Crosshair, Map, MessageCircle, AlertOctagon, RefreshCw, Clock, AlertTriangle, Compass, LayoutGrid, Asterisk } from "lucide-react";
import "./Navbar.css";

function Navbar({ hasNewIncident, clearNotification, user, role, handleLogout }) {
  const location = useLocation();

  const adminNavLinks = [
    { path: "/dashboard", label: "Overview", icon: LayoutDashboard },
    { path: "/cases", label: "Cases", icon: Folder, notify: hasNewIncident },
    { path: "/chat", label: "Chat Monitor", icon: MessageSquare },
    { path: "/analytics", label: "Analytics", icon: BarChart2 },
    { path: "/responders", label: "Responders", icon: Users },
    { path: "/resources", label: "Resources", icon: FileText },

  ];

  const patrolNavLinks = [
    { path: "/patrol/status", label: "Mission Control", icon: LayoutGrid },
  ];

  const navLinks = role === "patrol" ? patrolNavLinks : adminNavLinks;

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <Link to="/" className="brand-logo">
          <img src="/safetext_logo.png" alt="SafeText Logo" className="brand-logo-img" style={{ width: '100%', height: 'auto', maxHeight: '100px', objectFit: 'contain' }} />
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
      </div>
    </aside>
  );
}

export default Navbar;