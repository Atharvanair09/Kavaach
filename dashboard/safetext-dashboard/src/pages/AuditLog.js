import React, { useState, useEffect } from "react";
import { ClipboardList, Home } from "lucide-react";
import { Link } from "react-router-dom";
import { db } from "../services/firebase";
import { collection, query, orderBy, onSnapshot } from "firebase/firestore";

function AuditLog() {
  const [liveLogs, setLiveLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "audit_logs"), orderBy("timestamp", "desc"));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const logsData = snapshot.docs.map(doc => ({
        id: doc.id.substring(0, 8).toUpperCase(),
        ...doc.data(),
        // Format timestamp for display
        date: doc.data().timestamp?.toDate 
          ? doc.data().timestamp.toDate().toLocaleString() 
          : new Date().toLocaleString()
      }));
      setLiveLogs(logsData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return (
    <div className="page-container">
      <div className="card-header flex-header" style={{display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: '1rem'}}>
          <ClipboardList className="header-icon primary" />
          <div>
            <h2 style={{fontSize: '1.75rem', fontWeight: 800}}>Audit Log</h2>
            <p className="card-subtitle" style={{marginBottom: 0}}>Compliance tracking and historical actions</p>
          </div>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </div>

      <div className="card" style={{marginTop: '2rem'}}>
         {loading ? (
            <div style={{padding: '2rem', textAlign: 'center', color: '#64748b'}}>Loading logs...</div>
         ) : (
          <table style={{width: '100%', borderCollapse: 'collapse', textAlign: 'left'}}>
            <thead>
              <tr style={{borderBottom: '2px solid #e2e8f0'}}>
                <th style={{padding: '1rem', color: '#64748b'}}>Log ID</th>
                <th style={{padding: '1rem', color: '#64748b'}}>Timestamp</th>
                <th style={{padding: '1rem', color: '#64748b'}}>Action Type</th>
                <th style={{padding: '1rem', color: '#64748b'}}>Details</th>
                <th style={{padding: '1rem', color: '#64748b'}}>Source IP</th>
              </tr>
            </thead>
            <tbody>
              {liveLogs.length > 0 ? (
                liveLogs.map((log) => (
                  <tr key={log.id} style={{borderBottom: '1px solid #f1f5f9'}}>
                    <td style={{padding: '1rem', fontFamily: 'monospace', color: '#6366f1'}}>LOG-{log.id}</td>
                    <td style={{padding: '1rem', fontSize: '0.9rem', color: '#64748b'}}>{log.date}</td>
                    <td style={{padding: '1rem', fontWeight: 600}}>{log.action}</td>
                    <td style={{padding: '1rem'}}>{log.details}</td>
                    <td style={{padding: '1rem', fontSize: '0.85rem', color: '#94a3b8'}}>{log.ip}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="5" style={{padding: '2rem', textAlign: 'center', color: '#94a3b8'}}>No audit logs found. Perform a login to see activity.</td>
                </tr>
              )
              }
            </tbody>
          </table>
         )}
      </div>
    </div>
  );
}

export default AuditLog;
