import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { db } from "../services/firebase";
import { collection, onSnapshot } from "firebase/firestore";
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
  Minus,
  Target,
  PhoneCall,
  Filter,
  Home
} from "lucide-react";
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import "./Dashboard.css";

// Fix for default Leaflet icon issue
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

function Dashboard({ incidents, updateStatus, role, user, patrolUnits }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [mapCenter, setMapCenter] = useState([19.0760, 72.8777]); // Mumbai
  const [userLocationLoaded, setUserLocationLoaded] = useState(false);
  const [safeHavenCount, setSafeHavenCount] = useState(0);

  // 📍 Get User's Current Location
  // 📍 Group fetching and location
  useEffect(() => {
    // 1. Get location
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setMapCenter([position.coords.latitude, position.coords.longitude]);
          setUserLocationLoaded(true);
        },
        () => setUserLocationLoaded(true)
      );
    } else {
      setUserLocationLoaded(true);
    }

    // 2. Fetch Safe Haven Count
    const unsub = onSnapshot(collection(db, "safe_havens"), (snapshot) => {
      setSafeHavenCount(snapshot.docs.length);
    });

    return () => unsub();
  }, []);

  // Filter Active SOS and Missed Check-ins
  const activeIncidentMarkers = incidents.filter(i => 
    (i.status === "Pending" || i.status === "In Progress") && 
    (i.category === "Emergency" || i.text?.toLowerCase().includes("missed check-in")) &&
    i.lat && i.lng
  );

  // Filter Active Responders with locations
  const responderMarkers = patrolUnits.filter(p => 
    p.availability === "active" && p.lat && p.lng
  );

  // Simplified stats for the "one-to-one" look
  // Calculate Real Stats
  const stats = [
    { 
      label: "Active SOS Alerts", 
      value: incidents.filter(i => i.status === "Pending" && i.category === "Emergency").length, 
      icon: Asterisk, 
      type: "sos", 
      badge: incidents.filter(i => i.status === "Pending" && i.category === "Emergency").length > 0 ? "CRITICAL" : null 
    },
    { 
      label: "Ongoing Emergencies", 
      value: incidents.filter(i => i.status === "In Progress").length, 
      icon: AlertTriangle, 
      type: "emergency" 
    },
    { 
      label: "Safe Havens", 
      value: safeHavenCount,
      icon: Home, 
      type: "sharing" 
    },
    { 
      label: "Check-in Misses", 
      value: incidents.filter(i => i.text?.toLowerCase().includes("missed")).length, 
      icon: UserMinus, 
      type: "misses" 
    },
    { 
      label: "Resolved Total", 
      value: incidents.filter(i => i.status === "Resolved").length, 
      icon: CheckCircle, 
      type: "resolved" 
    }
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
        <div className="map-container-v2">
          {userLocationLoaded && (
            <MapContainer 
              center={mapCenter} 
              zoom={13} 
              scrollWheelZoom={false}
              style={{ height: '100%', width: '100%' }}
            >
              <TileLayer
                url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
              />
              
              {/* Current User Marker */}
              <Marker 
                position={mapCenter}
                icon={L.divIcon({
                  className: 'user-location-marker',
                  html: `<div style="
                    background: url(${user?.photo || '/sarah_avatar.png'});
                    background-size: cover;
                    border: 3px solid #3b82f6;
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    box-shadow: 0 0 15px rgba(59,130,246,0.8);
                    background-color: white;
                  "></div>`,
                  iconSize: [32, 32],
                  iconAnchor: [16, 16]
                })}
              >
                <Popup>
                  <strong>📍 You are here</strong><br/>
                  {user?.name || 'Current Admin'}
                </Popup>
              </Marker>
              
              {/* Dynamic Incident Markers (SOS / Missed Check-ins) */}
              {activeIncidentMarkers.map(incident => (
                <Marker 
                  key={incident.id} 
                  position={[incident.lat, incident.lng]}
                  icon={L.divIcon({
                    className: 'custom-incident-marker',
                    html: `
                      <div style="filter: drop-shadow(0px 4px 6px rgba(239, 68, 68, 0.5));">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="#ef4444" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                          <circle cx="12" cy="10" r="3" fill="white"></circle>
                        </svg>
                      </div>
                    `,
                    iconSize: [32, 32],
                    iconAnchor: [16, 32],
                    popupAnchor: [0, -32]
                  })}
                >
                  <Popup>
                    <div className="popup-content">
                      <strong style={{color: '#ef4444'}}>
                        {incident.category === "Emergency" ? "🚨 SOS ALERT" : "⚠️ MISSED CHECK-IN"}
                      </strong><br/>
                      <span>{incident.text || "No details available"}</span><br/>
                      <small>ID: {incident.id.substring(0, 8)}</small>
                      
                      {incident.category === "Emergency" && (
                        <div style={{ marginTop: '10px' }}>
                          {incident.assignedTo ? (
                            <div style={{ 
                              background: '#3b82f6', 
                              color: 'white', 
                              padding: '6px 12px', 
                              borderRadius: '4px', 
                              fontSize: '11px',
                              fontWeight: 'bold',
                              textAlign: 'center'
                            }}>
                              ASSIGNED: {patrolUnits.find(p => p.id === incident.assignedTo)?.name || 'Processing...'}
                            </div>
                          ) : (
                            <Link 
                              to={`/responders?caseId=${incident.id}`} 
                              style={{
                                background: '#ef4444', 
                                color: 'white', 
                                padding: '6px 12px', 
                                borderRadius: '4px', 
                                textDecoration: 'none', 
                                fontSize: '12px',
                                fontWeight: 'bold',
                                display: 'inline-block',
                                textAlign: 'center',
                                width: '100%'
                              }}
                            >
                              DISPATCH RESPONDERS
                            </Link>
                          )}
                        </div>
                      )}
                    </div>
                  </Popup>
                </Marker>
              ))}

              {/* Dynamic Responder Markers */}
              {responderMarkers.map(responder => (
                <Marker 
                  key={responder.id} 
                  position={[responder.lat, responder.lng]}
                  icon={L.divIcon({
                    className: 'responder-icon',
                    html: `<div style="background: #3b82f6; border: 2px solid white; width: 12px; height: 12px; border-radius: 50%; box-shadow: 0 0 10px rgba(59,130,246,0.5)"></div>`
                  })}
                >
                  <Popup>
                    <strong>👮 {responder.name}</strong><br/>
                    Status: {responder.availability}
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          )}

          {activeIncidentMarkers.some(i => i.category === "Emergency") && (
            <div className="active-sos-label">
              <div className="sos-label-header">ACTIVE SOS</div>
              <div className="sos-label-id">
                ID: #{activeIncidentMarkers.find(i => i.category === "Emergency").id.substring(0, 5).toUpperCase()}
              </div>
            </div>
          )}
        </div>

        {/* Incident Feed */}
        <aside className="incident-feed-card">
          <div className="feed-header">
            <h2>Active Incident Feed</h2>
            <span className="live-updates-tag">Live Updates</span>
          </div>
          
          <div className="feed-list">
            {incidents.filter(inc => inc.status !== "Resolved").slice(0, 5).map((incident) => (
              <div key={incident.id} className={`feed-item ${incident.category?.toLowerCase() === 'emergency' ? 'sos' : incident.category?.toLowerCase() === 'medical' ? 'miss' : 'safezone'}`}>
                <div className="feed-item-top">
                  <span className="feed-item-title">{incident.category} {incident.category === 'Emergency' ? 'Triggered' : 'Reported'}</span>
                  <span className="feed-item-time">{incident.timestamp}</span>
                </div>
                <span className="feed-item-user">ID: {incident.id.substring(0, 8)}</span>
                <p className="feed-item-msg" style={{margin: '4px 0 8px 0'}}>{incident.text}</p>
                
                <div className="feed-actions">
                  {incident.status === "Pending" && (
                    <button className="btn-dispatch" onClick={() => updateStatus(incident.id, "In Progress")}>DISPATCH</button>
                  )}
                  <button className="btn-details">DETAILS</button>
                </div>
              </div>
            ))}

            {incidents.filter(inc => inc.status !== "Resolved").length === 0 && (
              <div className="empty-feed-msg">
                <p>No active incidents at this time.</p>
              </div>
            )}
          </div>

          <Link to="/audit-log" className="view-history-link">
            View Full Audit Log
          </Link>
        </aside>
      </div>
    </div>
  );
}

export default Dashboard;