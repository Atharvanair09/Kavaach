import React, { useState } from "react";
import { Link } from "react-router-dom";
import {
  Search,
  Bell,
  Settings,
  FileDown,
  Plus,
  Asterisk,
  AlertTriangle,
  Navigation,
  UserMinus,
  CheckCircle,
  MoreHorizontal,
  Minus,
  Target,
  PhoneCall
} from "lucide-react";
import "./Dashboard.css";

function Dashboard({ incidents, updateStatus, role, user, patrolUnits }) {
  const [searchQuery, setSearchQuery] = useState("");

  // Simplified stats for the "one-to-one" look
  const stats = [
    { label: "Active SOS Alerts", value: "3", icon: Asterisk, type: "sos", badge: "CRITICAL" },
    { label: "Ongoing Emergencies", value: "8", icon: AlertTriangle, type: "emergency" },
    { label: "Sharing Location", value: "142", icon: Navigation, type: "sharing" },
    { label: "Check-in Misses", value: "12", icon: UserMinus, type: "misses" },
    { label: "Resolved Today", value: "24", icon: CheckCircle, type: "resolved" }
  ];

  return (
    <div className="dashboard-container">
      {/* Top Navigation */}
      <nav className="top-nav">
        <div className="search-container">
          <Search className="search-icon" size={18} />
          <input
            type="text"
            className="search-input"
            placeholder="Search incidents, users, or tags..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <div className="nav-right">
          <div className="nav-icons">
            <button className="icon-btn">
              <Bell size={20} />
              <span className="notification-dot"></span>
            </button>
            <button className="icon-btn">
              <Settings size={20} />
            </button>
          </div>
          <div className="user-profile">
            <div className="user-info">
              <span className="user-name">Sarah Connor</span>
              <span className="user-role">Senior Admin</span>
            </div>
            <img src="/sarah_avatar.png" alt="User Profile" className="user-avatar" />
          </div>
        </div>
      </nav>

      {/* Header Row */}
      <div className="dashboard-header-row">
        <div className="header-left">
          <h1>Live Overview</h1>
          <p>Real-time surveillance and incident management portal.</p>
        </div>
        <div className="header-actions">
          <button className="btn-export">
            <FileDown size={18} />
            Export Report
          </button>
          <button className="btn-new-case">
            <Plus size={18} />
            New Case
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="stats-row">
        {stats.map((stat, idx) => (
          <div key={idx} className={`stat-card-v2 ${stat.type}`}>
            {stat.badge && (
              <span className="status-label-badge critical">{stat.badge}</span>
            )}
            <div className="stat-icon-badge">
              <stat.icon size={20} />
            </div>
            <span className="stat-v2-value">{stat.value}</span>
            <span className="stat-v2-label">{stat.label}</span>
          </div>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="dashboard-main-grid">
        {/* Map Section */}
        <section className="map-container-v2">
          <img src="/map_bg.png" alt="City Map" className="map-mock" />
          
          <div className="map-controls-top">
            <button className="map-control-pill active">
              <span className="dot" style={{backgroundColor: '#3b82f6'}}></span>
              Users
            </button>
            <button className="map-control-pill">
              <span className="dot" style={{backgroundColor: '#ef4444'}}></span>
              SOS
            </button>
            <button className="map-control-pill">
              <span className="dot" style={{backgroundColor: '#10b981'}}></span>
              Responders
            </button>
          </div>

          <div className="active-sos-label">
            <div className="sos-label-header">ACTIVE SOS</div>
            <div className="sos-label-id">ID: #99283-A</div>
          </div>

          <div className="map-controls-bottom">
            <button className="map-action-btn"><Plus size={20} /></button>
            <button className="map-action-btn"><Minus size={20} /></button>
            <button className="map-action-btn"><Target size={20} /></button>
          </div>
        </section>

        {/* Incident Feed */}
        <aside className="incident-feed-card">
          <div className="feed-header">
            <h2>Active Incident Feed</h2>
            <span className="live-updates-tag">Live Updates</span>
          </div>
          
          <div className="feed-list">
            <div className="feed-item sos">
              <div className="feed-item-top">
                <span className="feed-item-title">SOS Triggered</span>
                <span className="feed-item-time">2m ago</span>
              </div>
              <span className="feed-item-user">User ID: USER_8829</span>
              <div className="feed-actions">
                <button className="btn-dispatch">DISPATCH</button>
                <button className="btn-details">DETAILS</button>
              </div>
            </div>

            <div className="feed-item miss">
              <div className="feed-item-top">
                <span className="feed-item-title">Check-in Missed</span>
                <span className="feed-item-time">12m ago</span>
              </div>
              <span className="feed-item-user">User ID: USER_1142</span>
              <div className="feed-item-msg">
                <PhoneCall size={12} />
                Attempting Voice Contact...
              </div>
            </div>

            <div className="feed-item safezone">
              <div className="feed-item-top">
                <span className="feed-item-title">Safe-Zone Exit</span>
                <span className="feed-item-time">18m ago</span>
              </div>
              <span className="feed-item-user">User ID: USER_4498</span>
              <div className="feed-item-msg">
                Transit monitoring initiated via automatic protocol 4.2
              </div>
            </div>

            <div className="feed-item resolved">
              <div className="feed-item-top">
                <span className="feed-item-title">Incident Resolved</span>
                <span className="feed-item-time">45m ago</span>
              </div>
              <p className="feed-item-msg" style={{margin: 0}}>Case #8821-C Closed</p>
            </div>
          </div>

          <Link to="/history" className="view-history-link">
            View Full History Log
          </Link>
        </aside>
      </div>
    </div>
  );
}

export default Dashboard;