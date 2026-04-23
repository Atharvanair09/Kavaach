import React, { useState } from "react";
import { Filter, Download, ArrowRightLeft, Mail, TriangleAlert, CheckCircle, Search, Bell, Settings, UserPlus, ChevronLeft, ChevronRight } from "lucide-react";
import "./Responders.css";

function Responders({ user, role, patrolUnits = [], incidents = [] }) {
  const [searchQuery, setSearchQuery] = useState("");

  const respondersData = patrolUnits.map(unit => {
    const activeCases = incidents.filter(i => i.assignedTo === unit.id && i.status === "In Progress").length;
    const maxLoad = 5;
    const loadPercentage = Math.min(Math.round((activeCases / maxLoad) * 100), 100);
    
    let statusLabel = "Offline";
    let statusColor = "gray";
    
    if (unit.availability === "active") {
        statusLabel = "Available";
        statusColor = "green";
    } else if (unit.availability === "busy") {
        statusLabel = "Busy";
        statusColor = "yellow";
    }

    return {
      id: unit.id,
      name: unit.name || "Unknown Officer",
      role: unit.role || "Patrol Officer",
      avatar: unit.photo || "/sarah_avatar.png",
      status: statusLabel,
      statusColor: statusColor,
      loadNum: activeCases,
      loadMax: maxLoad,
      loadPct: loadPercentage,
      avgResp: "4.2m" // Placeholder metric for now
    };
  });

  const activeResponders = respondersData.filter(r => r.status !== "Offline").length;
  const totalResponders = respondersData.length;

  const [activeTab, setActiveTab] = useState("All Responders");

  const filteredResponders = respondersData.filter(res => {
    const matchesSearch = res.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                         res.role.toLowerCase().includes(searchQuery.toLowerCase());
    
    if (activeTab === "Available") return matchesSearch && res.status === "Available";
    if (activeTab === "On Duty") return matchesSearch && res.status === "Busy";
    return matchesSearch;
  });

  return (
    <div className="responders-page">
      {/* Top Nav */}
      <nav className="top-nav">
        <div className="search-container">
          <Search className="search-icon" size={18} />
          <input
            type="text"
            className="search-input"
            placeholder="Search responders by name or role..."
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
              referrerPolicy="no-referrer"
            />
          </div>
        </div>
      </nav>

      <div className="responders-content">
        <div className="page-header-top">
          <div className="header-text">
            <h1>Responder Management</h1>
            <p>Manage emergency response personnel, monitor real-time workloads, and coordinate immediate crisis intervention.</p>
          </div>
          <div className="header-stats">
             <div className="stat-pill">
               <label>ACTIVE NOW</label>
               <h3>{activeResponders}/{totalResponders}</h3>
             </div>
             <div className="stat-pill">
               <label>TOTAL CASES</label>
               <h3>{incidents.filter(i => i.status !== "Resolved").length}</h3>
             </div>
          </div>
        </div>

        <div className="responders-table-container">
          <div className="table-controls">
            <div className="tabs-group">
              <button 
                className={`tab-btn ${activeTab === "All Responders" ? "active" : ""}`}
                onClick={() => setActiveTab("All Responders")}
              >All Responders</button>
              <button 
                className={`tab-btn ${activeTab === "Available" ? "active" : ""}`}
                onClick={() => setActiveTab("Available")}
              >Available</button>
              <button 
                className={`tab-btn ${activeTab === "On Duty" ? "active" : ""}`}
                onClick={() => setActiveTab("On Duty")}
              >On Duty</button>
            </div>
            <div className="action-btns">
               <button className="btn-outline-gray"><Filter size={14}/> Filter</button>
               <button className="btn-outline-gray"><Download size={14}/> Export</button>
            </div>
          </div>

          <table>
            <thead>
              <tr>
                <th>RESPONDER</th>
                <th>STATUS</th>
                <th>CASELOAD</th>
                <th>AVG RESPONSE</th>
                <th style={{textAlign: 'right'}}>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {filteredResponders.map(res => (
                <tr key={res.id} className={res.status === 'Offline' ? 'row-fade' : ''}>
                  <td>
                    <div className="responder-cell">
                      <div className="avatar-wrapper">
                        <img src={res.avatar} alt={res.name} onError={(e)=>{e.target.style.display='none'}} />
                        <span className={`status-dot ${res.statusColor}`}></span>
                      </div>
                      <div className="responder-info">
                        <h4>{res.name}</h4>
                        <p>{res.role}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className={`status-pill ${res.status.toLowerCase()}`}>
                       <span className="dot"></span> {res.status}
                    </span>
                  </td>
                  <td>
                    <div className="caseload-cell">
                      <div className="caseload-top">
                        <span>{res.loadNum}/{res.loadMax}</span>
                        <span style={{ color: res.loadPct === 100 ? '#ef4444' : '#94a3b8' }}>{res.loadPct}%</span>
                      </div>
                      <div className="progress-bar">
                        <div className="progress-fill" style={{ 
                          width: `${res.loadPct}%`, 
                          background: res.loadPct === 100 ? '#ef4444' : (res.loadPct === 0 ? '#e2e8f0' : '#2563eb')
                        }}></div>
                      </div>
                    </div>
                  </td>
                  <td className="metrics-cell">
                    {res.avgResp}
                  </td>
                  <td style={{textAlign: 'right'}}>
                     <div className="actions-cell" style={{justifyContent: 'flex-end'}}>
                       <button className="icon-action" style={{opacity: res.status === 'Offline' ? 0.3 : 1}}><ArrowRightLeft size={16}/></button>
                       <button className="icon-action" style={{opacity: res.status === 'Offline' ? 0.3 : 1}}><Mail size={16}/></button>
                       <button className="btn-gray-pill" style={{opacity: res.status === 'Offline' ? 0.5 : 1}}>View History</button>
                     </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="pagination">
            <span className="pagination-info">Showing {respondersData.length} of {totalResponders} responders</span>
              <div className="pagination-controls">
               <button className="page-btn"><ChevronLeft size={16}/></button>
               <button className="page-btn active">1</button>
               <button className="page-btn">2</button>
               <button className="page-btn dots">...</button>
               <button className="page-btn"><ChevronRight size={16}/></button>
            </div>
          </div>
        </div>

        <div className="bottom-grid">
           {/* Load Balancing Board */}
           <div className="load-card">
              <div className="load-content">
                 <h2>Load Balancing Required</h2>
                 <p>System has detected high traffic in the Eastern region. Three responders are currently at maximum capacity. Consider re-routing non-critical cases.</p>
                 <button className="btn-white">Optimize Workload</button>
              </div>
              <div className="load-graphic">
                 <h3>12</h3>
                 <span>QUEUED CASES</span>
                 <svg width="80" height="80" style={{position: 'absolute', bottom: '-15px', right: '-15px', opacity: 0.3}} viewBox="0 0 24 24" fill="white">
                    <circle cx="12" cy="12" r="5" />
                    <circle cx="4" cy="5" r="3" />
                    <circle cx="21" cy="7" r="2.5" />
                    <circle cx="6" cy="20" r="3.5" />
                    <circle cx="20" cy="19" r="2.5" />
                    <line x1="12" y1="12" x2="4" y2="5" stroke="white" strokeWidth="2" />
                    <line x1="12" y1="12" x2="21" y2="7" stroke="white" strokeWidth="2" />
                    <line x1="12" y1="12" x2="6" y2="20" stroke="white" strokeWidth="2" />
                    <line x1="12" y1="12" x2="20" y2="19" stroke="white" strokeWidth="2" />
                 </svg>
              </div>
           </div>

           {/* Alerts */}
           <div className="alerts-card">
              <h3>Recent Alerts</h3>
              
              <div className="alert-item">
                 <div className="alert-icon red">
                    <TriangleAlert size={18} />
                 </div>
                 <div className="alert-text">
                    <h4>Emergency Response Needed</h4>
                    <p>Case #8827 has been waiting &gt; 5 mins</p>
                 </div>
              </div>

              <div className="alert-item">
                 <div className="alert-icon green">
                    <CheckCircle size={18} />
                 </div>
                 <div className="alert-text">
                    <h4>Marcus Thorne Handover</h4>
                    <p>Shift completion confirmed</p>
                 </div>
              </div>
           </div>

           <div className="fab-btn">
              <UserPlus size={24} strokeWidth={2.5} />
           </div>
        </div>
      </div>
    </div>
  );
}

export default Responders;
