import React, { useState } from "react";

import { 
  Filter, 
  Plus, 
  MoreHorizontal, 
  MessageSquare, 
  TrendingDown, 
  MapPin, 
  Clock,
  Search,
  Bell,
  Settings
} from "lucide-react";
import "./Cases.css";

// Import the generated map image
const MAP_IMAGE = "/case_map.png"; 

function Cases({ user, role }) {
  const [searchQuery, setSearchQuery] = useState("");

  const kanbanData = [

    {
      id: "New",
      count: 12,
      dotClass: "new",
      cards: [
        {
          id: "#ST-9821",
          time: "4m ago",
          title: "Manual SOS",
          priority: "High Priority",
          priorityClass: "high",
          hasImage: true,
          location: "51.5074° N, 0.1278° W",
          user: "UN",
          action: "Claim Case"
        },
        {
          id: "#ST-9815",
          time: "12m ago",
          title: "AI Flag: Pattern Shift",
          priority: "Standard",
          priorityClass: "standard",
          assignee: "James L."
        }
      ]
    },
    {
      id: "In Progress",
      count: 8,
      dotClass: "in-progress",
      cards: [
        {
          id: "#ST-9702",
          status: "Active Chat",
          title: "Missed Check-in",
          priority: "Follow-up",
          priorityClass: "follow-up",
          user: "Elena R.",
          isTyping: true,
          hasChat: true
        }
      ]
    },
    {
      id: "Escalated",
      count: 3,
      dotClass: "escalated",
      cards: [
        {
          id: "#ST-9644",
          isCritical: true,
          title: "Voice Alert: Danger",
          priority: "Critical",
          priorityClass: "critical",
          msg: "Local law enforcement notified. Arrival in 6 mins.",
          user: "Marcus Thorne"
        }
      ]
    },
    {
      id: "Resolved",
      count: 45,
      dotClass: "resolved",
      cards: [
        {
          id: "#ST-9588",
          isResolved: true,
          title: "AI Flag: False Positive",
          priority: "Closed",
          priorityClass: "standard",
          user: "Resolved by Dr. Sarah"
        }
      ]
    }
  ];

  return (
    <div className="cases-container">
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
              <span className="user-name">{user?.name || "Dashboard User"}</span>
              <span className="user-role">{role === "admin" ? "Senior Admin" : "Crime Patrol"}</span>
            </div>
            <img 
              src={user?.photo || "/sarah_avatar.png"} 
              alt="User Profile" 
              className="user-avatar" 
              onError={(e) => { e.target.src = "/sarah_avatar.png" }}
            />
          </div>
        </div>
      </nav>

      {/* Header */}

      <header className="cases-header">
        <div className="header-title">
          <h1>Case Management</h1>
          <p>Real-time incident response board for active sessions.</p>
        </div>
        <div className="header-actions">
          <button className="btn-filters">
            <Filter size={18} />
            Filters
          </button>
          <button className="btn-new-case">
            <Plus size={18} />
            New Case
          </button>
        </div>
      </header>

      {/* Kanban Board */}
      <div className="kanban-board">
        {kanbanData.map((column) => (
          <div key={column.id} className="kanban-column">
            <div className="column-header">
              <div className="column-title">
                <span className={`dot ${column.dotClass}`}></span>
                {column.id} <span className="case-count">{column.count}</span>
              </div>
              <MoreHorizontal size={18} className="more-btn" />
            </div>

            {column.cards.map((card, idx) => (
              <div key={idx} className="case-card">
                <div className="card-top">
                  <span className="case-id">{card.id}</span>
                  {card.time && <span className="case-time">{card.time}</span>}
                  {card.status && <span className="active-chat">{card.status}</span>}
                  {card.isResolved && <span className="status-badge">✓</span>}
                  {card.isCritical && <span className="case-time" style={{color: '#ef4444'}}>•</span>}
                </div>
                
                <h3 className="case-title">{card.title}</h3>
                <span className={`priority-tag ${card.priorityClass}`}>{card.priority}</span>

                {card.hasImage && (
                  <div className="card-image">
                    <img src={MAP_IMAGE} alt="Location Map" />
                    <div className="location-overlay">
                      <MapPin size={10} /> {card.location}
                    </div>
                  </div>
                )}

                {card.msg && <p className="msg-bubble">{card.msg}</p>}

                <div className="card-footer">
                  <div className="assignee">
                    <div className="avatar"></div>
                    <span className="assignee-name">
                      {card.assignee ? `Assigned: ${card.assignee}` : card.user ? card.user : "UN"}
                      {card.isTyping && <span style={{fontSize: '10px', marginLeft: '4px', color: '#10b981'}}>Typing...</span>}
                    </span>
                  </div>
                  {card.action ? (
                    <span className="claim-link">{card.action}</span>
                  ) : card.hasChat ? (
                    <MessageSquare size={16} className="active-chat-icon" />
                  ) : null}
                </div>
              </div>
            ))}
          </div>
        ))}
      </div>

      {/* Bottom Analytics */}
      <div className="bottom-analytics">
        <div className="trends-card">
          <div className="trends-header">
            <h2>Weekly Incident Trends</h2>
            <p>Automated analysis showing a 12% decrease in manual SOS triggers this week.</p>
          </div>
          <div className="chart-container">
             <div className="bar-group"><div className="bar" style={{height: '40%'}}></div></div>
             <div className="bar-group"><div className="bar" style={{height: '60%'}}></div></div>
             <div className="bar-group"><div className="bar" style={{height: '30%'}}></div></div>
             <div className="bar-group"><div className="bar" style={{height: '90%'}}></div></div>
             <div className="bar-group"><div className="bar" style={{height: '50%'}}></div></div>
             <div className="bar-group"><div className="bar" style={{height: '80%'}}></div></div>
             <div className="bar-group"><div className="bar highlight" style={{height: '70%'}}></div></div>
          </div>
        </div>

        <div className="response-time-card">
          <div className="rt-header">Avg Response Time</div>
          <div className="rt-value">1.4<span>min</span></div>
          <div className="rt-trend">
            <TrendingDown size={18} />
            18% faster than last month
          </div>
        </div>
      </div>
    </div>
  );
}

export default Cases;
