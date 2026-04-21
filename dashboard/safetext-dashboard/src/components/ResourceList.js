import React, { useState } from "react";
import { 
  Phone, Globe, Shield, HeartPulse, Scale, AlertCircle, Home, 
  Search, Bell, Settings, Filter, ArrowUpRight, Plus, CheckCircle2,
  MapPin, Clock, Bed, ShieldCheck, DoorOpen, Users, Maximize2, ShieldAlert
} from "lucide-react";
import "./ResourceList.css";

function ResourceList({ user, role }) {
  const [searchQuery, setSearchQuery] = useState("");

  const resources = [
    {
      id: 1,
      name: "Central Mercy Hospital",
      borderClass: "border-blue",
      iconClass: "dark-blue",
      icon: <HeartPulse size={20}/>,
      pillText: "OPEN 24/7",
      pillClass: "green",
      location: "0.8km away • Downtown Core",
      phone: "+1 (555) 012-3456",
      featureIcon: <Bed size={16}/>,
      featureText: "8 emergency beds available"
    },
    {
      id: 2,
      name: "North District Precinct",
      borderClass: "border-dark-blue",
      iconClass: "blue",
      icon: <Shield size={20}/>,
      pillText: "VERIFIED SAFE",
      pillClass: "blue",
      location: "1.4km away • Oak Ridge",
      phone: "+1 (555) 019-8677",
      featureIcon: <ShieldCheck size={16}/>,
      featureText: "Secure waiting area available"
    },
    {
      id: 3,
      name: "Haven Women's Shelter",
      borderClass: "border-red",
      iconClass: "red",
      icon: <DoorOpen size={20}/>,
      pillText: "LIMITED SPACE",
      pillClass: "yellow",
      location: "2.1km away • West Gardens",
      phone: "+1 (555) 014-9900",
      featureIcon: <AlertCircle size={16} strokeWidth={3}/>,
      featureText: "3 beds remaining for tonight",
      featureRed: true
    },
    {
      id: 4,
      name: "Unity Health Clinic",
      borderClass: "border-blue",
      iconClass: "dark-blue",
      icon: <HeartPulse size={20}/>,
      pillText: "OPEN NOW",
      pillClass: "green",
      location: "3.6km away • East Valley",
      phone: "+1 (555) 017-2233",
      featureIcon: <Clock size={16}/>,
      featureText: "Closes at 10:00 PM"
    },
    {
      id: 5,
      name: "St. Jude Community Center",
      borderClass: "border-blue",
      iconClass: "blue",
      icon: <Home size={20}/>,
      pillText: "HIGH CAPACITY",
      pillClass: "green",
      location: "4.2km away • Southside",
      phone: "+1 (555) 011-5544",
      featureIcon: <Users size={16}/>,
      featureText: "Family-friendly facilities"
    }
  ];

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
            <button className="toggle-btn active">List View</button>
            <button className="toggle-btn">Map View</button>
          </div>
        </div>

        <div className="filter-pills">
           <button className="filter-pill active"><Filter size={16}/> All Resources</button>
           <button className="filter-pill"><Shield size={16}/> Police Stations</button>
           <button className="filter-pill"><HeartPulse size={16}/> Medical Centers</button>
           <button className="filter-pill"><ShieldAlert size={16}/> Crisis Shelters</button>
           <button className="filter-pill"><Scale size={16}/> Support Centers</button>
        </div>

        <div className="resources-grid">
           {resources.map(res => (
             <div key={res.id} className={`resource-card ${res.borderClass}`}>
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
           
           {/* Submit New Resource Card */}
           <div className="submit-card">
              <div className="plus-circle">
                 <Plus size={24} strokeWidth={3}/>
              </div>
              <h4>Submit New Resource</h4>
              <p>Help expand our network by suggesting verified safe havens.</p>
           </div>
        </div>

        <div className="bottom-grid">
           {/* Map Component Placeholder */}
           <div className="map-card">
              <div className="live-map-pill">LIVE MAP COVERAGE</div>
              
              {/* Map background generation */}
              <div style={{
                position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
                backgroundColor: '#a3a3a3',
                backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 19px, rgba(255,255,255,0.4) 19px, rgba(255,255,255,0.4) 20px), repeating-linear-gradient(90deg, transparent, transparent 19px, rgba(255,255,255,0.4) 19px, rgba(255,255,255,0.4) 20px)',
                backgroundSize: '20px 20px',
                opacity: 0.8
              }}>
                 {/* Landmass graphic simulation */}
                 <svg width="100%" height="100%" viewBox="0 0 400 300" preserveAspectRatio="none">
                    <path d="M -50 400 L -50 150 Q 50 120 100 80 T 200 20 T 350 -20 L 450 -20 L 450 400 Z" fill="#d4d4d4" />
                 </svg>
                 
                 {/* Map Points */}
                 <div style={{position: 'absolute', top: '45%', left: '30%', background: '#0561f0', width: 24, height: 24, borderRadius: '50%', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 10px rgba(0,0,0,0.2)'}}>
                    <Shield size={12}/>
                 </div>
                 <div style={{position: 'absolute', top: '75%', left: '60%', background: '#f43f5e', width: 24, height: 24, borderRadius: '50%', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 10px rgba(0,0,0,0.2)'}}>
                    <DoorOpen size={12}/>
                 </div>
                 
                 {/* Small generic map pins */}
                 <MapPin size={16} color="#737373" style={{position: 'absolute', top: '30%', left: '42%'}}/>
                 <MapPin size={16} color="#737373" style={{position: 'absolute', top: '25%', left: '65%'}}/>
                 <MapPin size={16} color="#737373" style={{position: 'absolute', top: '55%', left: '55%'}}/>
                 <MapPin size={16} color="#737373" style={{position: 'absolute', top: '70%', left: '25%'}}/>
              </div>

              <button className="expand-map-btn">
                 <Maximize2 size={16}/> Expand Full Map
              </button>
           </div>

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

      </div>
    </div>
  );
}

export default ResourceList;