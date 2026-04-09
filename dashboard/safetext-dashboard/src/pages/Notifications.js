import React, { useState, useEffect } from "react";
import { Bell, Info, AlertTriangle, CheckCircle, Home } from "lucide-react";
import { Link } from "react-router-dom";
import { db } from "../services/firebase";
import { collection, query, orderBy, onSnapshot } from "firebase/firestore";

function Notifications() {
  const [liveNotifications, setLiveNotifications] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "notifications"), orderBy("timestamp", "desc"));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const notes = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        // Convert timestamp to "X mins ago" or local time
        time: doc.data().timestamp?.toDate 
          ? doc.data().timestamp.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
          : "Just now"
      }));
      setLiveNotifications(notes);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const getIcon = (type) => {
    switch(type) {
      case "alert": return <AlertTriangle className="danger" size={20} />;
      case "success": return <CheckCircle className="success" size={20} style={{color: '#10b981'}} />;
      case "info": return <Info className="primary" size={20} color="#3b82f6" />;
      default: return <Bell size={20} />;
    }
  };

  return (
    <div className="page-container">
      <div className="card-header flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <Bell className="header-icon primary" />
          <div>
            <h2 style={{fontSize: '1.75rem', fontWeight: 800}}>System Notifications</h2>
            <p className="card-subtitle" style={{marginBottom: 0}}>Recent alerts, updates, and dispatcher logs</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </div>

      <div className="card" style={{marginTop: '2rem'}}>
        {loading ? (
            <div style={{padding: '2rem', textAlign: 'center', color: '#64748b'}}>Retrieving alerts...</div>
        ) : (
          <div style={{display: 'flex', flexDirection: 'column', gap: '1rem'}}>
            {liveNotifications.length > 0 ? (
              liveNotifications.map(n => (
                <div key={n.id} style={{ display: 'flex', gap: '1rem', padding: '1rem', borderRadius: '8px', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0' }}>
                   <div style={{paddingTop: '2px'}}>
                     {getIcon(n.type)}
                   </div>
                   <div style={{flex: 1}}>
                     <p style={{margin: '0 0 4px 0', fontWeight: 500, color: '#1e293b'}}>{n.text}</p>
                     <span style={{fontSize: '0.8rem', color: '#64748b'}}>{n.time}</span>
                   </div>
                </div>
              ))
            ) : (
              <div style={{padding: '2rem', textAlign: 'center', color: '#94a3b8'}}>No recent notifications. System is clear.</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default Notifications;
