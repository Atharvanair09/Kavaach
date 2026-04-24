import React, { useState, useEffect } from "react";
import { 
  Phone, Globe, Shield, HeartPulse, Scale, AlertCircle, Home, 
  Search, Bell, Settings, Filter, ArrowUpRight, Plus, CheckCircle2,
  MapPin, Clock, Bed, ShieldCheck, DoorOpen, Users, Maximize2, ShieldAlert,
  Send, List, Map as MapIcon
} from "lucide-react";
import "./ResourceList.css";
import { db } from "../services/firebase";
import { collection, onSnapshot, addDoc, serverTimestamp } from "firebase/firestore";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

// Fix for default Leaflet marker icons
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

function ResourceList({ user, role }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [havens, setHavens] = useState([]);
  const [isExpanded, setIsExpanded] = useState(false);
  const [activeFilter, setActiveFilter] = useState("all");
  const [showSubmitModal, setShowSubmitModal] = useState(false);
  const [viewMode, setViewMode] = useState("list");
  const [newResource, setNewResource] = useState({
    name: "",
    type: "Medical",
    location: "",
    phone: "",
    capacity: ""
  });

  // --- Real-time Safe Havens Fetching ---
  useEffect(() => {
    const q = collection(db, "safe_havens");
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => {
        const rawData = doc.data();
        const type = (rawData.type || rawData.category || "emergency").toLowerCase();
        const name = (rawData.name || "").toLowerCase();
        console.log(`🔍 CLASSIFYING: "${rawData.name}" | Type: "${type}"`);

        // Map Firestore data to the UI structure (Police: Green, Medical: Yellow, Shelters: Orange)
        const isPolice = type.includes('police') || name.includes('police') || name.includes('precinct');
        const isMedical = type.includes('medical') || type.includes('hospital') || type.includes('health') || 
                          name.includes('hospital') || name.includes('clinic') || name.includes('medical');
        
        return {
          id: doc.id,
          ...doc.data(),
          lat: doc.data().lat || 19.0760 + (Math.random() - 0.5) * 0.05, // Fallback for demo
          lng: doc.data().lng || 72.8777 + (Math.random() - 0.5) * 0.05,
          borderClass: isPolice ? 'border-green' : (isMedical ? 'border-purple' : 'border-orange'),
          iconClass: isPolice ? 'green' : (isMedical ? 'purple' : 'orange'),
          icon: isMedical ? <HeartPulse size={20}/> : (isPolice ? <Shield size={20}/> : <DoorOpen size={20}/>),
          pillText: doc.data().status || "OPEN 24/7",
          pillClass: isPolice ? 'green' : (isMedical ? 'purple' : 'orange'),
          location: doc.data().location || "Location Unknown",
          phone: doc.data().phone || "No phone listed",
          featureIcon: isMedical ? <Bed size={16}/> : <ShieldCheck size={16}/>,
          featureText: doc.data().featureText || "Verified Safety Protocols",
          featureRed: doc.data().status === 'LIMITED SPACE'
        };
      });
      setHavens(data);
    });
    return () => unsubscribe();
  }, []);

  const handleSubmitResource = async (e) => {
    e.preventDefault();
    if (!newResource.name) return;
    
    try {
      await addDoc(collection(db, "safe_havens"), {
        ...newResource,
        status: "PENDING VERIFICATION",
        timestamp: serverTimestamp(),
        submittedBy: user?.name || "Anonymous"
      });
      setNewResource({ name: "", type: "Medical", location: "", phone: "", capacity: "" });
      setShowSubmitModal(false);
      alert("Resource submitted for verification!");
    } catch (e) {
      console.error("Error adding resource:", e);
    }
  };

  const filteredHavens = havens.filter(haven => {
    const matchesSearch = haven.name.toLowerCase().includes(searchQuery.toLowerCase());
    if (activeFilter === "all") return matchesSearch;
    if (activeFilter === "police") return matchesSearch && (haven.type.includes('police') || haven.name.toLowerCase().includes('police') || haven.name.toLowerCase().includes('precinct'));
    if (activeFilter === "medical") return matchesSearch && (haven.type.includes('medical') || haven.type.includes('hospital') || haven.type.includes('health') || haven.name.toLowerCase().includes('hospital') || haven.name.toLowerCase().includes('clinic'));
    if (activeFilter === "shelter") return matchesSearch && (!haven.type.includes('police') && !haven.type.includes('medical') && !haven.type.includes('hospital'));
    return matchesSearch;
  });

  const displayedHavens = isExpanded 
    ? filteredHavens 
    : (activeFilter === "all" ? filteredHavens.slice(0, 5) : filteredHavens.slice(0, 6));

  return (
    <div className="resources-page">
      {/* Top Nav */}
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

      <div className="resources-content">
        <div className="page-header-top">
          <div className="header-text">
            <h1>Resource Directory</h1>
            <p>Verified safe havens, medical facilities, and emergency shelters available for immediate assistance.</p>
          </div>
          <div className="view-toggle">
            <button 
              className={`toggle-btn ${viewMode === "list" ? "active" : ""}`}
              onClick={() => setViewMode("list")}
            >
              <List size={16}/> List View
            </button>
            <button 
              className={`toggle-btn ${viewMode === "map" ? "active" : ""}`}
              onClick={() => setViewMode("map")}
            >
              <MapIcon size={16}/> Map View
            </button>
          </div>
        </div>

        <div className="filter-pills">
           <button 
             className={`filter-pill ${activeFilter === "all" ? "active" : ""}`}
             onClick={() => setActiveFilter("all")}
           >
             <Filter size={16}/> All Resources
           </button>
           <button 
             className={`filter-pill police ${activeFilter === "police" ? "active" : ""}`}
             onClick={() => setActiveFilter("police")}
           >
             <Shield size={16}/> Police Stations
           </button>
           <button 
             className={`filter-pill medical ${activeFilter === "medical" ? "active" : ""}`}
             onClick={() => setActiveFilter("medical")}
           >
             <HeartPulse size={16}/> Medical Centers
           </button>
           <button 
             className={`filter-pill shelter ${activeFilter === "shelter" ? "active" : ""}`}
             onClick={() => setActiveFilter("shelter")}
           >
             <ShieldAlert size={16}/> Crisis Shelters
           </button>  
        </div>

        {viewMode === "list" ? (
          <div className="resources-grid">
            {displayedHavens.map((res, idx) => (
              <div key={res.id} className={`resource-card ${res.borderClass}`} style={{ animationDelay: `${idx * 0.05}s` }}>
                  <div className="card-top">
                    <div className={`icon-box ${res.iconClass}`}>{res.icon}</div>
                    <span className={`status-pill ${res.pillClass}`}>{res.pillText}</span>
                  </div>
                  <h3>{res.name}</h3>
                  <div className="location-info">
                    <MapPin size={14}/> {res.location}
                  </div>
                  <div className="contact-row">
                    <div className="contact-phone">
                        <Phone size={16} color="#0561f0"/> {res.phone}
                    </div>
                  </div>
                  <div className={`availability-row ${res.featureRed ? 'red' : ''}`}>
                    {res.featureIcon} {res.featureText}
                  </div>
                  <div className="card-footer">
                    <a href="#" className="view-map-link">View on Map <ArrowUpRight size={14}/></a>
                    <button className="arrow-btn"><ArrowUpRight size={16}/></button>
                  </div>
              </div>
            ))}
            
            {!isExpanded && activeFilter === "all" && (
              <div 
                className="submit-card" 
                style={{ animationDelay: '0.3s' }}
                onClick={() => setShowSubmitModal(true)}
              >
                  <div className="plus-circle">
                    <Plus size={24} strokeWidth={3}/>
                  </div>
                  <h4>Submit New Resource</h4>
                  <p>Help expand our network by suggesting verified safe havens.</p>
              </div>
            )}
          </div>
        ) : (
          <div className="resources-map-container">
            <MapContainer 
              center={[19.0760, 72.8777]} 
              zoom={13} 
              style={{ height: "600px", width: "100%", borderRadius: "24px" }}
            >
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
              {filteredHavens.map(haven => {
                const color = haven.iconClass === 'green' ? '#10b981' : (haven.iconClass === 'purple' ? '#7c3aed' : '#ea580c');
                const customIcon = L.divIcon({
                  className: 'custom-marker',
                  html: `<div style="background-color: ${color}; width: 30px; height: 30px; border-radius: 50%; border: 3px solid white; box-shadow: 0 4px 6px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; color: white;">
                           <div style="width: 8px; height: 8px; background: white; border-radius: 50%;"></div>
                         </div>`,
                  iconSize: [30, 30],
                  iconAnchor: [15, 30]
                });

                return (
                  <Marker 
                    key={haven.id} 
                    position={[haven.lat, haven.lng]} 
                    icon={customIcon}
                  >
                    <Popup>
                      <div className="map-popup-content">
                        <strong>{haven.name}</strong><br/>
                        <span style={{ color: color, fontWeight: 'bold' }}>{haven.type.toUpperCase()}</span><br/>
                        {haven.location}<br/>
                        {haven.phone}
                      </div>
                    </Popup>
                  </Marker>
                );
              })}
            </MapContainer>
          </div>
        )}

        {viewMode === "list" && filteredHavens.length > (activeFilter === "all" ? 5 : 6) && role === "admin" && (
          <div className="see-more-container">
            <button className="see-more-btn" onClick={() => setIsExpanded(!isExpanded)}>
              {isExpanded ? "Show Less" : `See All ${filteredHavens.length} Resources`}
            </button>
          </div>
        )}


        <div className="bottom-grid">
           {/* Verification Standards */}
           <div className="verification-card">
              <div className="badge-icon">
                 <CheckCircle2 size={36} color="#93c5fd" fill="rgba(255,255,255,0.1)"/>
              </div>
              <h3>Verification<br/>Standards</h3>
              <p>Every resource listed is manually vetted by our team to ensure it meets strict safety and privacy protocols. Updated every 30 minutes.</p>
              
              <div className="check-list">
                 <div className="check-item"><CheckCircle2 size={16}/> Physical Safety Audit</div>
                 <div className="check-item"><CheckCircle2 size={16}/> Staff Background Checks</div>
                 <div className="check-item"><CheckCircle2 size={16}/> Privacy Compliance</div>
              </div>

              <button className="btn-review">Review Protocol</button>
           </div>
        </div>

        {/* Submission Modal */}
        {showSubmitModal && (
          <div className="modal-overlay" onClick={() => setShowSubmitModal(false)}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
              <div className="modal-header">
                <div className="submit-icon-box">
                  <Plus size={24} />
                </div>
                <div className="header-text">
                  <h3>Submit Safe Haven</h3>
                  <p>Suggest a verified location for our directory.</p>
                </div>
                <button className="close-modal" onClick={() => setShowSubmitModal(false)}>×</button>
              </div>

              <form className="modal-form" onSubmit={handleSubmitResource}>
                <div className="form-row">
                  <div className="field">
                    <label>Facility Name</label>
                    <input 
                        type="text" 
                        placeholder="e.g. City General Hospital" 
                        value={newResource.name}
                        onChange={e => setNewResource({...newResource, name: e.target.value})}
                        required
                    />
                  </div>
                  <div className="field">
                    <label>Resource Type</label>
                    <select 
                        value={newResource.type}
                        onChange={e => setNewResource({...newResource, type: e.target.value})}
                    >
                        <option value="Medical">Medical Facility</option>
                        <option value="Police">Police Precinct</option>
                        <option value="Emergency">Crisis Shelter</option>
                    </select>
                  </div>
                </div>

                <div className="field full">
                  <label>Address / Precise Location</label>
                  <div className="input-with-icon">
                    <MapPin size={16} />
                    <input 
                        type="text" 
                        placeholder="Street address, city, and zip" 
                        value={newResource.location}
                        onChange={e => setNewResource({...newResource, location: e.target.value})}
                        required
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="field">
                    <label>Contact Phone</label>
                    <div className="input-with-icon">
                      <Phone size={16} />
                      <input 
                          type="text" 
                          placeholder="+1 (555) 000-0000" 
                          value={newResource.phone}
                          onChange={e => setNewResource({...newResource, phone: e.target.value})}
                          required
                      />
                    </div>
                  </div>
                  <div className="field">
                    <label>Verification Status</label>
                    <div className="status-indicator">
                      <CheckCircle2 size={16} color="#10b981"/> Automated Check Active
                    </div>
                  </div>
                </div>

                <div className="modal-footer">
                  <button type="button" className="btn-cancel" onClick={() => setShowSubmitModal(false)}>Cancel</button>
                  <button type="submit" className="btn-submit">
                    Submit for Vetting <Send size={16} />
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}

export default ResourceList;