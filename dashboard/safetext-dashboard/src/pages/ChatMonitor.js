import React, { useState, useEffect, useRef } from "react";
import { MessageSquare, AlertCircle, Home, Search, Bell, Settings, Video, Camera, Mic } from "lucide-react";
import { collection, onSnapshot, query, orderBy, limit } from "firebase/firestore";
import { db } from "../services/firebase";
import "./ChatMonitor.css";

function ChatMonitor({ user, role }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [liveChats, setLiveChats] = useState([]);
  const [activeIncidents, setActiveIncidents] = useState([]);
  const [selectedSessionId, setSelectedSessionId] = useState(null);
  const chatContainerRef = useRef(null);

  // 1. Fetch Real-time messages for the selected session
  useEffect(() => {
    if (!selectedSessionId) {
      setLiveChats([]);
      return;
    }

    const q = query(
      collection(db, "chats"), 
      orderBy("time", "asc"),
      limit(100)
    );
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetched = snapshot.docs
        .map((doc) => {
          const d = doc.data();
          return {
            id: doc.id,
            ...d,
            timestamp: d.time,
            timeLabel: d.time?.toDate ? d.time.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "Just now",
            dateLabel: d.time?.toDate ? d.time.toDate().toLocaleDateString([], { weekday: 'long', day: 'numeric', month: 'short' }) : ""
          };
        })
        .filter(msg => msg.sessionId === selectedSessionId);
      
      setLiveChats(fetched);
    }, (error) => console.error("Messages Error:", error));
    
    return () => unsubscribe();
  }, [selectedSessionId]);

  // 2. Fetch Real-time chats for the sidebar and group by session
  useEffect(() => {
    const q = query(collection(db, "chats"), orderBy("time", "desc"), limit(100));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const grouped = {};
      
      snapshot.docs.forEach((doc) => {
        const d = doc.data();
        const sid = d.sessionId || "unknown";
        
        // Only keep the most recent message for each session
        if (!grouped[sid] || (d.time?.seconds > (grouped[sid].time?.seconds || 0))) {
          grouped[sid] = {
            id: doc.id,
            sessionId: sid,
            ...d,
            displayTime: d.time?.toDate ? d.time.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "Recently",
            priority: d.risk === 'high' ? 'High' : (d.risk === 'critical' ? 'Urgent' : 'Normal')
          };
        }
      });

      const sorted = Object.values(grouped).sort((a, b) => (b.time?.seconds || 0) - (a.time?.seconds || 0));
      setActiveIncidents(sorted);

      // Initialize selected session if none
      if (!selectedSessionId && sorted.length > 0) {
        setSelectedSessionId(sorted[0].sessionId);
      }
    }, (error) => console.error("Chats Error:", error));
    
    return () => unsubscribe();
  }, [selectedSessionId]);

  // Auto-scroll chat to bottom
  useEffect(() => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [liveChats]);

  return (
    <div className="page-container">
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

      <div className="card-header flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <MessageSquare className="header-icon primary" />
          <div>
            <h2 style={{fontSize: '1.75rem', fontWeight: 800}}>Live Chat Monitor</h2>
            <p className="card-subtitle" style={{marginBottom: 0}}>NLP Chatbot transcripts and live distress channels</p>
          </div>
        </div>
      </div>

      <div className="chat-monitor-container">
        {/* Left Sidebar: Real Data Flags */}
        <div className="flagged-chats-sidebar">
          <div className="sidebar-header ios-style">
            <h3>Messages</h3>
            <button className="ios-msg-btn"><AlertCircle size={20} /></button>
          </div>
          <div className="flagged-list ios-list">
            {activeIncidents.length === 0 ? (
              <div className="ios-empty-sidebar">No active flags</div>
            ) : (
              activeIncidents.map((incident) => (
                <div 
                  key={incident.sessionId} 
                  className={`flagged-item ios-item ${selectedSessionId === incident.sessionId ? 'active' : ''}`}
                  onClick={() => setSelectedSessionId(incident.sessionId)}
                >
                  {(incident.priority === 'High' || incident.priority === 'Urgent') && <span className="unread-dot"></span>}
                  <div className={`ios-avatar ${incident.priority === 'Normal' ? 'gray' : ''}`}>
                    {(incident.userId || incident.user || "U").substring(0,2).toUpperCase()}
                  </div>
                  <div className="ios-item-content">
                    <div className="ios-item-top">
                      <span className="ios-username">{incident.userId || incident.user || `Session ${incident.sessionId.substring(0,4)}`}</span>
                      <span className="ios-time">{incident.displayTime}</span>
                      <span className="ios-chevron"></span>
                    </div>
                    <p className="ios-snippet">{incident.message || "Message encrypted..."}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Center: iPhone Mockup with Dynamic Data */}
        <div className="conversation-pane mockup-mode">
          <div className="iphone-frame">
            <div className="dynamic-island"></div>
            
            <div className="iphone-screen">
              <div className="ios-chat-header">
                <div className="header-left-btn">‹</div>
                <div className="header-center">
                  <div className="ios-header-avatar">UN</div>
                  <span className="ios-header-name">Active Conversation</span>
                </div>
                <div className="header-right-btn">
                  <Video size={18} color="#007aff" />
                </div>
              </div>

              <div className="ios-chat-content" ref={chatContainerRef}>
                {liveChats.length > 0 && liveChats[0].dateLabel && (
                  <div className="ios-date-stamp">{liveChats[0].dateLabel}</div>
                )}
                {liveChats.length === 0 ? (
                  <div className="ios-empty">Establishing encrypted bridge...</div>
                ) : (
                  liveChats.map((c, idx) => (
                    <React.Fragment key={c.id}>
                      <div className="ios-msg-wrapper human">
                        <div className={`ios-bubble ${c.risk === 'high' || c.risk === 'critical' ? 'danger' : ''}`}>
                          {c.message}
                        </div>
                        <span className="ios-msg-time">{c.timeLabel}</span>
                      </div>
                      {c.reply && (
                        <div className="ios-msg-wrapper bot">
                          <div className="ios-bubble">
                            {c.reply}
                          </div>
                          <div className="ios-bot-footer">
                            <span className="ios-msg-time">{c.timeLabel}</span>
                            {idx === liveChats.length - 1 && <span className="ios-delivered">Delivered</span>}
                          </div>
                        </div>
                      )}
                    </React.Fragment>
                  ))
                )}
              </div>

              <div className="ios-input-bar">
                <Camera size={24} color="#8e8e93" />
                <div className="ios-plus-icon">+</div>
                <div className="ios-input-pill">
                  <span className="ios-placeholder">iMessage</span>
                  <Mic size={18} color="#8e8e93" />
                </div>
              </div>
              <div className="ios-home-indicator"></div>
            </div>
          </div>
        </div>

        {/* Right Sidebar: Actions */}
        <div className="actions-sidebar">
          <div className="action-section">
            <h4 className="section-title">URGENT ACTIONS</h4>
            <button className="btn-take-over">
              <MessageSquare size={18} /> Take Over Chat
            </button>
            <button className="btn-dispatch">
              <AlertCircle size={18} /> Dispatch Responder
            </button>
          </div>

          <div className="action-section">
            <h4 className="section-title">QUICK RESOLUTION</h4>
            <div className="quick-actions">
              <button className="resolution-item">
                <h5>Escalate to Professional</h5>
                <p>Connect with clinical specialist</p>
              </button>
              <button className="resolution-item">
                <h5>Send Safety Plan</h5>
                <p>Push personalized guide to user</p>
              </button>
              <button className="resolution-item">
                <h5>Verify Identity/Loc</h5>
                <p>Request high-precision GPS</p>
              </button>
            </div>
          </div>

          <div className="user-context-card">
            <h4 className="section-title">User Context</h4>
            <div className="context-grid">
              <div className="context-row"><span>Location</span><strong>San Francisco, CA</strong></div>
              <div className="context-row"><span>Device</span><strong>iOS Native App</strong></div>
              <div className="context-row"><span>History</span><strong className="red">3 Past Flags</strong></div>
            </div>
            <div className="severity-meter">
              <div className="meter-header"><span>Severity Score: 94/100</span></div>
              <div className="meter-bar"><div className="meter-fill" style={{width: '94%'}}></div></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default ChatMonitor;
