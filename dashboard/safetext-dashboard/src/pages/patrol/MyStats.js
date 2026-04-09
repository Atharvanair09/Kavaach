import React, { useState, useEffect } from "react";
import { collection, query, where, onSnapshot, orderBy } from "firebase/firestore";
import { db } from "../../services/firebase";

function MyStats({ incidents, user }) {
  const [radioMessages, setRadioMessages] = useState([]);
  const unitId = user?.id || "P1";

  // --- Listen to this unit's radio activity for the log ---
  useEffect(() => {
    // Simplified query to avoid index requirement crash
    const q = query(
      collection(db, "unit_messages"), 
      where("senderId", "==", unitId)
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      // Sort locally by timestamp desc
      data.sort((a, b) => {
        const timeA = a.timestamp?.toMillis() || 0;
        const timeB = b.timestamp?.toMillis() || 0;
        return timeB - timeA;
      });
      setRadioMessages(data);
    });
    return () => unsubscribe();
  }, [unitId]);

  // --- Metric Calculations ---
  const myIncidents = incidents?.filter(i => i.assignedTo === unitId) || [];
  
  const handledCount = myIncidents.filter(i => i.status === "In Progress" || i.status === "Resolved").length;
  const resolvedCount = myIncidents.filter(i => i.status === "Resolved").length;
  const rejectedCount = myIncidents.filter(i => i.status === "Rejected").length;
  
  // Mock responsiveness (can be detailed later with actual timestamps)
  const avgResponse = handledCount > 0 ? (3.5 + (handledCount * 0.1)).toFixed(1) : "0.0";

  // --- Construct Dynamic Shift Log ---
  const incidentEvents = myIncidents.map(i => {
    let title = "Status Update";
    let dot = "blue";
    if (i.status === "In Progress") { title = "Case Accepted"; dot = "green"; }
    if (i.status === "Resolved") { title = "Case Resolved"; dot = "green-alt"; }
    if (i.status === "Rejected") { title = "Case Declined"; dot = "red"; }

    return {
      time: i.timestamp ? new Date(i.timestamp.toDate()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "Recently",
      dot: dot,
      title: `${title} #${i.id.slice(-4)}`,
      desc: `— ${i.text || i.message || "Incident details recorded"}`
    };
  });

  const messageEvents = radioMessages.slice(0, 5).map(m => ({
    time: m.timestamp ? new Date(m.timestamp.toDate()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "Recently",
    dot: "blue",
    title: "Radio Transmission",
    desc: `— Broadcast: "${m.text.substring(0, 30)}${m.text.length > 30 ? '...' : ''}"`
  }));

  const shiftLog = [...incidentEvents, ...messageEvents].sort((a, b) => b.time.localeCompare(a.time)).slice(0, 8);

  return (
    <div className="patrol-page-container">
      <div className="patrol-header">
        <h2>My Performance Stats</h2>
        <p>Real-time summary for <strong>UNIT {unitId}</strong> — cases handled and shift activity.</p>
        <button className="btn-export">Export report</button>
      </div>

      <div className="stats-top-grid">
        <div className="stat-card minimal">
           <h3 className="stat-big blue-text">{handledCount}</h3>
           <p className="stat-label">Cases handled<br/>today</p>
           <span className="stat-trend green-text">Activity: High</span>
        </div>
        <div className="stat-card minimal">
           <h3 className="stat-big green-text">{avgResponse}<span className="unit">m</span></h3>
           <p className="stat-label">Avg response<br/>time</p>
           <span className="stat-trend green-text">Below average</span>
        </div>
        <div className="stat-card minimal">
           <h3 className="stat-big orange-text">{rejectedCount}</h3>
           <p className="stat-label">Cases rejected</p>
           <span className="stat-trend red-text">Logged in feed</span>
        </div>
        <div className="stat-card minimal">
           <h3 className="stat-big green-text-alt">{resolvedCount}</h3>
           <p className="stat-label">Scenes secured</p>
           <span className="stat-trend green-text">Great work!</span>
        </div>
      </div>

      <div className="patrol-widgets-grid grid-1-2">
        {/* Left column: Performance Breakdown */}
        <div className="widget-card stats-widget">
          <div className="widget-header">
            <h3 className="uppercase-tracking">PERFORMANCE ANALYTICS</h3>
          </div>
          
          <div className="cases-by-type-list">
             <div className="type-row">
                <span className="type-name">Accepted</span>
                <div className="type-bar-track"><div className="type-bar bg-green" style={{width: `${(handledCount/10)*100}%`}}></div></div>
                <span className="type-count">{handledCount}</span>
             </div>
             <div className="type-row">
                <span className="type-name">Resolved</span>
                <div className="type-bar-track"><div className="type-bar bg-blue" style={{width: `${(resolvedCount/10)*100}%`}}></div></div>
                <span className="type-count">{resolvedCount}</span>
             </div>
             <div className="type-row">
                <span className="type-name">Declined</span>
                <div className="type-bar-track"><div className="type-bar bg-red" style={{width: `${(rejectedCount/10)*100}%`}}></div></div>
                <span className="type-count">{rejectedCount}</span>
             </div>
             <div className="type-row">
                <span className="type-name">Radio Logs</span>
                <div className="type-bar-track"><div className="type-bar bg-orange" style={{width: `${(radioMessages.length/20)*100}%`}}></div></div>
                <span className="type-count">{radioMessages.length}</span>
             </div>
          </div>
        </div>

        {/* Right column: Shift Log */}
        <div className="widget-card log-widget">
          <div className="widget-header">
            <h3 className="uppercase-tracking">LIVE ACTION LOG</h3>
          </div>
          
          <div className="shift-log-timeline">
             {shiftLog.length > 0 ? shiftLog.map((log, i) => (
               <div key={i} className="log-item">
                  <div className="log-time">{log.time}</div>
                  <div className={`log-dot ${log.dot}-bg`}></div>
                  <div className="log-content">
                     <strong>{log.title}</strong> {log.desc}
                  </div>
               </div>
             )) : (
               <div style={{padding: '2rem', textAlign: 'center', color: '#94a3b8'}}>No activity logged for this shift yet.</div>
             )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default MyStats;
