import React, { useState, useEffect } from "react";
import { MessageSquare, AlertCircle, Home } from "lucide-react";
import { Link } from "react-router-dom";
import { collection, onSnapshot, query, orderBy, limit } from "firebase/firestore";
import { db } from "../services/firebase";
import "./ChatMonitor.css";

function ChatMonitor() {
  const [liveChats, setLiveChats] = useState([]);

  const chatContainerRef = React.useRef(null);

  useEffect(() => {
    // 1. First try the 'messages' collection
    const messagesQuery = query(
      collection(db, "messages"),
      orderBy("timestamp", "desc"),
      limit(30)
    );

    const unsubscribeMessages = onSnapshot(messagesQuery, (snapshot) => {
      if (!snapshot.empty) {
        const data = snapshot.docs.map(doc => {
          const d = doc.data();
          return {
            id: doc.id,
            user: d.userId || d.user || "Anonymous User",
            intent: d.intent || "General",
            message: d.message || d.text || "...",
            time: d.timestamp?.toDate ? d.timestamp.toDate().toLocaleTimeString() : new Date().toLocaleTimeString(),
            isDanger: d.intent === "danger" || d.priority === "High"
          };
        });
        setLiveChats(data.reverse()); // Reverse to show latest at bottom for chat feel
      } else {
        // Fallback to 'incidents' if messages is empty
        const incidentsQuery = query(
          collection(db, "incidents"),
          orderBy("timestamp", "desc"),
          limit(30)
        );
        onSnapshot(incidentsQuery, (incidentSnapshot) => {
          const incidentData = incidentSnapshot.docs.map(doc => {
            const d = doc.data();
            return {
              id: doc.id,
              user: d.reporter || "SafeText User",
              intent: d.category || "Incident",
              message: d.message || "...",
              time: d.timestamp?.toDate ? d.timestamp.toDate().toLocaleTimeString() : new Date().toLocaleTimeString(),
              isDanger: d.threat_level === "HIGH"
            };
          });
          setLiveChats(incidentData.reverse());
        });
      }
    }, (error) => {
      console.error("Firestore Error:", error);
    });

    return () => unsubscribeMessages();
  }, []);

  // Auto-scroll to bottom
  useEffect(() => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [liveChats]);

  return (
    <div className="page-container">
      <div className="card-header flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <MessageSquare className="header-icon primary" />
          <div>
            <h2 style={{fontSize: '1.75rem', fontWeight: 800}}>Live Chat Monitor</h2>
            <p className="card-subtitle" style={{marginBottom: 0}}>NLP Chatbot transcripts and live distress channels</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </div>

      <div className="card chat-monitor-card" style={{marginTop: '2rem', padding: '0'}}>
        <div 
          className="chat-messages-container" 
          ref={chatContainerRef}
          style={{ height: '500px', overflowY: 'auto', padding: '1.5rem' }}
        >
          {liveChats.length === 0 ? (
            <div style={{padding: '4rem', textAlign: 'center', color: '#64748b'}}>
              <MessageSquare size={48} style={{opacity: 0.2, marginBottom: '1rem'}} />
              <p>No messages yet...</p>
            </div>
          ) : (
            <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
              {liveChats.map((c) => (
                <div 
                  key={c.id} 
                  className={`chat-message-item ${c.isDanger ? 'danger-intent' : ''}`}
                  style={{
                    padding: '1rem',
                    borderRadius: '12px',
                    backgroundColor: c.isDanger ? 'var(--danger)' : '#f8fafc',
                    color: c.isDanger ? '#fff' : 'inherit',
                    border: '1px solid var(--border)',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.02)',
                    transition: 'all 0.2s'
                  }}
                >
                  <div style={{display: 'flex', justifyContent: 'space-between', marginBottom: '4px'}}>
                    <strong style={{fontSize: '0.9rem'}}>{c.user}</strong>
                    <span style={{fontSize: '0.75rem', opacity: 0.7}}>{c.time}</span>
                  </div>
                  <p style={{margin: '4px 0', fontSize: '1rem', lineHeight: '1.5'}}>{c.message}</p>
                  {c.intent && (
                    <div style={{marginTop: '8px'}}>
                      <span style={{
                        fontSize: '0.7rem', 
                        fontWeight: 800, 
                        padding: '2px 8px', 
                        borderRadius: '4px',
                        background: c.isDanger ? 'rgba(255,255,255,0.2)' : 'rgba(59,130,246,0.1)',
                        color: c.isDanger ? '#fff' : 'var(--primary)',
                        textTransform: 'uppercase'
                      }}>
                        {c.intent}
                      </span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default ChatMonitor;
