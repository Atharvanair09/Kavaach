import React, { useState, useEffect, useRef } from "react";
import { Mic, Send, Radio as RadioIcon, Volume2, Shield, ChevronDown, Bell, AlertTriangle } from "lucide-react";
import { collection, addDoc, onSnapshot, query, orderBy, serverTimestamp, where } from "firebase/firestore";
import { db } from "../../services/firebase";
import "./Communication.css";

function Communication({ incidents, user, role }) {
  const [radioInput, setRadioInput] = useState("");
  const [messages, setMessages] = useState([]);
  const messagesEndRef = useRef(null);

  // --- Real-time Radio Messages (Session Based) ---
  useEffect(() => {
    // Capture the exact moment this session started
    const sessionStartTime = new Date();
    
    // Only listen for messages created after the page reloaded
    const q = query(
      collection(db, "unit_messages"), 
      orderBy("timestamp", "asc"),
      where("timestamp", ">=", sessionStartTime)
    );
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setMessages(data);
    });
    return () => unsubscribe();
  }, []);

  // Auto-scroll
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const processBotResponse = async (userText) => {
    const text = userText.toLowerCase();
    const unitId = user?.id || 'Unit';
    let reply = "";

    // 1. Emergency / Conflict Situations
    if (text.includes("followed") || text.includes("stalking") || text.includes("trailing")) {
      reply = `Dispatch: Copy ${unitId}. Incident categorized as STALKING. Stay within visual range of the victim. Direct her to the nearest Safe-Zone while we monitor via CCTV.`;
    } 
    else if (text.includes("backup") || text.includes("need help") || text.includes("urgent") || text.includes("danger")) {
      const locationMatch = text.match(/(?:at|near|in)\s+([a-zA-Z0-9\s]+)/i);
      const location = locationMatch ? locationMatch[1] : "your current sector";
      reply = `🚨 Dispatch: Priority Alert for ${unitId}. Backup units P2 and P3 have been diverted to ${location}. ETA 3-4 mins. Keep your frequency open.`;
    }
    // 2. Movement & Patrol Status
    else if (text.includes("heading") || text.includes("moving") || text.includes("reacing") || text.includes("entering")) {
      const destinationMatch = text.match(/(?:to|towards|into)\s+([a-zA-Z0-9\s]+)/i);
      const destination = destinationMatch ? destinationMatch[1] : "the target area";
      reply = `Dispatch: Acknowledged. Transitioning ${unitId} to active patrol at ${destination}. Report once signal strength is verified at destination.`;
    }
    else if (text.includes("arrived") || text.includes("reached") || text.includes("at location")) {
      reply = `Dispatch: Arrival logged for ${unitId}. Secure the perimeter and initiate zone inspection. Log any suspicious activity immediately.`;
    }
    // 3. Status Reports
    else if (text.includes("clearing") || text.includes("all quiet") || text.includes("status ok") || text.includes("no issues")) {
      const responses = [
        `Dispatch: Copy ${unitId}. Everything looks green from the control room. Maintain pattern.`,
        `Dispatch: Acknowledged. Good work. Continue primary sweep of Zone B-4.`,
        `Dispatch: Logged as Status-OK. Proceed to the next checkpoint.`
      ];
      reply = responses[Math.floor(Math.random() * responses.length)];
    }
    // 4. Case Management
    else if (text.includes("case") || text.includes("task") || text.includes("assign")) {
      reply = `Dispatch: Tasking protocols initiated. Ensure all unit members are briefed on the specific case parameters. Dispatch out.`;
    }

    if (reply) {
      setTimeout(async () => {
        await addDoc(collection(db, "unit_messages"), {
          text: reply,
          senderId: "DISPATCH",
          senderName: "DISPATCH CENTER",
          role: "admin",
          timestamp: serverTimestamp()
        });
      }, 1500);
    }
  };

  const handleTransmit = async () => {
    if (!radioInput.trim()) return;
    
    const originalInput = radioInput;
    try {
      await addDoc(collection(db, "unit_messages"), {
        text: radioInput,
        senderId: user?.id || "Unknown",
        senderName: user?.id === 'P1' ? "Alpha Unit" : (user?.id || "Officer"),
        role: role || "patrol",
        timestamp: serverTimestamp()
      });
      setRadioInput("");
      processBotResponse(originalInput);
    } catch (error) {
      console.error("Transmission Error:", error);
    }
  };

  // SOS Mock Data (representing urgent triggers)
  const sosAlerts = [
    { id: 1, user: "USER_8829", location: "Sector 4-B", time: "2m ago" },
    { id: 2, user: "USER_4499", location: "Central Mall", time: "15m ago" }
  ];

  // Grouped rejected incidents
  const rejectedIncidents = incidents?.filter(i => i.status === "Rejected") || [];

  return (
    <div className="patrol-page-container tactical">
      
      {/* 2. Tactical Content Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '400px 1fr', gap: '2rem', maxWidth: '1600px', margin: '0 auto', width: '100%', height: 'calc(100vh - 120px)' }}>
        
        {/* LHS: ALERTS PANEL */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', overflowY: 'auto' }}>
          
          {/* SOS ALERTS SECTION */}
          <div className="widget-card" style={{ background: '#fef2f2', border: '1px solid #fee2e2', padding: '1.5rem', borderRadius: '20px' }}>
             <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '1.5rem' }}>
               <Bell color="#dc2626" size={20} />
               <h3 style={{ color: '#dc2626', margin: 0, fontSize: '1.2rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '1px' }}>SOS Alert</h3>
             </div>
             
             <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {sosAlerts.map(sos => (
                   <div key={sos.id} style={{ padding: '1.25rem', background: '#ffffff', borderRadius: '16px', border: '1px solid #fee2e2', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)' }}>
                      <p style={{ margin: '0 0 5px 0', fontWeight: 800, color: '#1e293b', fontSize: '1rem' }}>Triggered by: {sos.user}</p>
                      <p style={{ margin: 0, fontSize: '0.85rem', color: '#64748b' }}>Location: {sos.location} • {sos.time}</p>
                   </div>
                ))}
             </div>
          </div>

          {/* CASES-MISSED SECTION */}
          <div className="widget-card" style={{ background: '#fffbeb', border: '1px solid #fef3c7', padding: '1.5rem', borderRadius: '20px' }}>
             <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '1.5rem' }}>
               <AlertTriangle color="#d97706" size={20} />
               <h3 style={{ color: '#d97706', margin: 0, fontSize: '1.2rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '1px' }}>Cases-Missed</h3>
             </div>
             
             <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {rejectedIncidents.length > 0 ? (
                  rejectedIncidents.map((task, idx) => (
                    <div key={idx} style={{ padding: '1.25rem', borderLeft: '4px solid #f59e0b', background: '#ffffff', borderRadius: '4px 16px 16px 4px', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)', border: '1px solid #fef3c7', borderLeftWidth: '4px' }}>
                       <p style={{ margin: '0 0 5px 0', fontWeight: 800, fontSize: '1rem', color: '#1e293b' }}>UNIT {task.assignedTo}</p>
                       <p style={{ margin: 0, fontSize: '0.9rem', color: '#64748b' }}>{task.text || task.message}</p>
                    </div>
                  ))
                ) : (
                  <p style={{ color: '#92400e', fontSize: '0.85rem', textAlign: 'center', padding: '1.5rem', background: 'rgba(251, 191, 36, 0.1)', borderRadius: '12px' }}>No missed cases reported.</p>
                )}
             </div>
          </div>
        </div>

        {/* RHS: TACTICAL RADIO */}
        <div className="zone-radio-container" style={{ height: '100%' }}>
          <div className="radio-panel-header">
            <div className="radio-panel-title">
              <div style={{ background: 'rgba(16, 185, 129, 0.2)', padding: '8px', borderRadius: '10px' }}>
                <RadioIcon size={20} color="#10b981" />
              </div>
              <div>
                <h3>Zone B-4 Radio</h3>
                <span className="units-online">4 units online</span>
              </div>
            </div>
            <div className="live-indicator">
              <span className="live-pulse"></span> LIVE
            </div>
          </div>

          <div className="tactical-chat-area">
            {messages.map((msg, i) => {
              const userMatch = (msg.senderId?.toLowerCase() === user?.id?.toLowerCase());
              const isDispatch = msg.senderId === "DISPATCH";
              const isMe = userMatch && !isDispatch;
              
              const timestamp = msg.timestamp ? new Date(msg.timestamp.toDate()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : "now";
              
              return (
                <div key={msg.id || i} className={`bubble-group ${isMe ? 'sent' : 'received'}`}>
                  <div className="bubble">
                    {msg.text}
                  </div>
                  <div className="bubble-meta">
                    {isMe ? 'YOU' : (msg.senderId || "Unknown")} • {timestamp}
                  </div>
                </div>
              );
            })}
            <div ref={messagesEndRef} />
          </div>

          <div className="tactical-input-container">
            <div className="tactical-input-wrapper">
              <input 
                className="tactical-input" 
                placeholder="Broadcast to zone..." 
                value={radioInput}
                onChange={(e) => setRadioInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleTransmit()}
              />
            </div>
            <button className="send-btn-circle" onClick={handleTransmit}>
              <Send size={20} />
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}

export default Communication;
