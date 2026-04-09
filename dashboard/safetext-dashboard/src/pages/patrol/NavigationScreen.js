import React from "react";
import { Link } from "react-router-dom";

function NavigationScreen() {
  const hotspots = [
    { type: "Robbery", loc: "Market Road junction", count: "7 incidents this month", time: "2d ago", color: "red" },
    { type: "Theft", loc: "Central Bus Stand", count: "5 incidents this month", time: "4d ago", color: "blue" },
    { type: "Vandalism", loc: "East wall, Sector 4", count: "3 incidents this month", time: "1w ago", color: "orange" },
    { type: "Assault", loc: "Shivaji Nagar bridge", count: "2 incidents this month", time: "1w ago", color: "red" },
  ];

  return (
    <div className="patrol-page-container">
      <div className="patrol-header">
        <h2>Navigation & Map</h2>
        <p>Hotspot pins and patrol zone — Zone B-4.</p>
      </div>

      <div className="patrol-widgets-grid grid-1-2">
        {/* Left column: Live Map */}
        <div className="widget-card map-widget">
          <div className="widget-header map-header">
            <h3>Zone<br/>B-4<br/>live<br/>map</h3>
            <div className="map-filters">
               <span className="filter-badge blue-bg">Users</span>
               <span className="filter-badge red-bg">SOS</span>
            </div>
          </div>
          
          <div className="dark-map-container">
             <div className="grid-lines">
               <div className="g-line-v v1"></div>
               <div className="g-line-v v2"></div>
               <div className="g-line-h h1"></div>
               <div className="g-line-h h2"></div>
               <div className="g-line-h h3"></div>
             </div>
             
             {/* Map Pins */}
             <div className="map-pin pin-r" style={{top: '40%', left: '30%'}}>R</div>
             <div className="map-pin pin-v" style={{top: '30%', left: '60%'}}>V</div>
             
             <div className="map-unit-marker" style={{top: '60%', left: '45%'}}>
               <div className="unit-dot"></div>
               <span className="unit-label">UNIT-047</span>
             </div>

             <div className="map-pin pin-t" style={{top: '75%', left: '20%'}}>T</div>
             <div className="map-pin pin-t2" style={{top: '80%', left: '45%'}}>T</div>
             <div className="map-pin pin-a" style={{top: '65%', left: '70%'}}>A</div>

             <div className="map-controls">
                <button>+</button>
                <button>−</button>
             </div>
          </div>
          <div className="scroll-more-indicator">
            <div className="scroll-arrow-circle">↓</div>
          </div>
        </div>

        {/* Right column: Hotspot Feed */}
        <div className="widget-card hotspot-widget">
          <div className="widget-header">
            <h3>Hotspot feed</h3>
            <span className="live-dot-text"><span className="dot green-dot"></span> LIVE UPDATES</span>
          </div>
          
          <div className="hotspot-list">
             {hotspots.map((h, i) => (
                <div key={i} className="hotspot-item">
                   <div className={`hotspot-type type-${h.color}`}>{h.type}</div>
                   <div className="hotspot-details">
                      <h4>{h.loc}</h4>
                      <p>{h.count}</p>
                   </div>
                   <div className="hotspot-time">{h.time}</div>
                </div>
             ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default NavigationScreen;
