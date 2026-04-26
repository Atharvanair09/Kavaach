import React, { useState } from "react";

import { 
  Clock,
  Filter,
  Plus,
  MoreHorizontal,
  TrendingDown,
  MapPin,
  MessageSquare
} from "lucide-react";
import TopNavbar from "../components/TopNavbar";
import "./Cases.css";
import { MapContainer, TileLayer, Marker } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix for default Leaflet icon issue
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

// Import the generated map image (unused now, kept for reference if needed)
const MAP_IMAGE = "/case_map.png"; 

function Cases({ user, role, incidents, updateStatus }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [expandedStates, setExpandedStates] = useState({});

  const toggleExpand = (columnId) => {
    setExpandedStates(prev => ({
      ...prev,
      [columnId]: !prev[columnId]
    }));
  };

  // Dynamic Kanban Mapping
  const kanbanData = [
    {
      id: "New",
      count: incidents.filter(i => i.status === "Pending" && i.priority !== "High").length,
      dotClass: "new",
      cards: incidents
        .filter(i => i.status === "Pending" && i.priority !== "High")
        .map(i => ({
          id: `#ST-${i.id.substring(0, 4).toUpperCase()}`,
          time: i.timestamp || "Just now",
          title: i.category === "Dispatch" ? i.text : `${i.category} Detected`,
          priority: i.priority,
          priorityClass: i.priority?.toLowerCase() || "standard",
          user: i.assignedTo || "Unassigned",
          action: "Claim Case",
          dbId: i.id,
          lat: i.lat,
          lng: i.lng,
          location: i.lat ? `${i.lat.toFixed(4)}° N, ${i.lng.toFixed(4)}° E` : "Location Unknown",
          hasMap: !!(i.lat && i.lng)
        }))
    },
    {
      id: "In Progress",
      count: incidents.filter(i => i.status === "In Progress").length,
      dotClass: "in-progress",
      cards: incidents
        .filter(i => i.status === "In Progress")
        .map(i => ({
          id: `#ST-${i.id.substring(0, 4).toUpperCase()}`,
          status: "Active Tracking",
          title: i.category === "Dispatch" ? i.text : `${i.category} Response`,
          priority: "Responding",
          priorityClass: "follow-up",
          user: i.assignedTo || "Unit Assigned",
          hasChat: true,
          dbId: i.id,
          lat: i.lat,
          lng: i.lng,
          location: i.lat ? `${i.lat.toFixed(4)}° N, ${i.lng.toFixed(4)}° E` : "Location Unknown",
          hasMap: !!(i.lat && i.lng)
        }))
    },
    {
      id: "Escalated",
      count: incidents.filter(i => i.status === "Pending" && i.priority === "High").length,
      dotClass: "escalated",
      cards: incidents
        .filter(i => i.status === "Pending" && i.priority === "High")
        .map(i => ({
          id: `#ST-${i.id.substring(0, 4).toUpperCase()}`,
          isCritical: true,
          title: i.category === "Emergency" ? "SOS ALERT: HELP" : i.text,
          priority: "Critical",
          priorityClass: "critical",
          msg: i.category === "Emergency" ? "Immediate dispatch required. Responder in route." : i.text,
          user: i.assignedTo || "Awaiting Dispatch",
          hasMap: !!(i.lat && i.lng),
          location: i.lat ? `${i.lat.toFixed(4)}° N, ${i.lng.toFixed(4)}° E` : "Location Unknown",
          lat: i.lat,
          lng: i.lng,
          dbId: i.id
        }))
    },
    {
      id: "Resolved",
      count: incidents.filter(i => i.status === "Resolved").length,
      dotClass: "resolved",
      cards: incidents
        .filter(i => i.status === "Resolved")
        .map(i => ({
          id: `#ST-${i.id.substring(0, 4).toUpperCase()}`,
          isResolved: true,
          title: `${i.category} Secured`,
          priority: "Closed",
          priorityClass: "standard",
          user: `Resolved by ${i.assignedTo || "Admin"}`,
          dbId: i.id,
          lat: i.lat,
          lng: i.lng,
          location: i.lat ? `${i.lat.toFixed(4)}° N, ${i.lng.toFixed(4)}° E` : "Location Unknown",
          hasMap: !!(i.lat && i.lng)
        }))
    }
  ];

  return (
    <div className="cases-container">
      <TopNavbar 
        user={user} 
        role={role} 
        searchQuery={searchQuery} 
        setSearchQuery={setSearchQuery} 
      />

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

            {column.cards
              .slice(0, expandedStates[column.id] ? undefined : 5)
              .map((card, idx) => (
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

                  {card.hasMap && card.lat && card.lng && (
                    <div className="card-image" style={{ height: '160px', position: 'relative' }}>
                      <MapContainer 
                        center={[card.lat, card.lng]} 
                        zoom={15} 
                        scrollWheelZoom={false}
                        zoomControl={false}
                        dragging={false}
                        doubleClickZoom={false}
                        style={{ height: '100%', width: '100%' }}
                      >
                        <TileLayer
                          url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}{r}.png"
                        />
                        <Marker position={[card.lat, card.lng]} />
                      </MapContainer>
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
                      <span 
                        className="claim-link" 
                        onClick={() => updateStatus(card.dbId, "In Progress")}
                        style={{cursor: 'pointer'}}
                      >
                        {card.action}
                      </span>
                    ) : card.hasChat ? (
                      <MessageSquare size={16} className="active-chat-icon" />
                    ) : null}
                  </div>
                </div>
              ))}

            {column.cards.length > 5 && (
              <button 
                className="see-more-btn" 
                onClick={() => toggleExpand(column.id)}
              >
                {expandedStates[column.id] ? "Show Less" : `+${column.cards.length - 5} More Cases`}
              </button>
            )}
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
