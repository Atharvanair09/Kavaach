import React, { useState, useEffect } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import { collection, query, orderBy, limit, onSnapshot } from "firebase/firestore";
import { db } from "../../services/firebase";
import "./NavigationScreen.css";

// Fix for default Leaflet marker icons
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
});

// Custom Icon for SOS Pulse
const sosIcon = L.divIcon({
  className: "sos-pulse-icon",
  html: '<div class="pulse-ring"></div><div class="pulse-dot"></div>',
  iconSize: [20, 20],
  iconAnchor: [10, 10],
});

// Helper component to auto-recenter map
function MapAutoRecenter({ position }) {
  const map = useMap();
  useEffect(() => {
    if (position) map.setView(position, 13);
  }, [position, map]);
  return null;
}

function NavigationScreen() {
  const [alerts, setAlerts] = useState([]);
  const [mapCenter, setMapCenter] = useState([19.2534, 72.8557]); // Default Mumbai coords

  useEffect(() => {
    // 1. Listen for SOS alerts from Firestore
    const q = query(
      collection(db, "sos_alerts"),
      orderBy("timestamp", "desc"),
      limit(10)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map((doc) => {
        const d = doc.data();
        // Handle both GeoPoint and old-style map locations
        let lat = 19.2534;
        let lng = 72.8557;

        if (d.location) {
          if (typeof d.location.latitude === "number") {
             lat = d.location.latitude;
             lng = d.location.longitude;
          } else if (typeof d.location.lat === "number") {
             lat = d.location.lat;
             lng = d.location.lng;
          }
        }

        return {
          id: doc.id,
          ...d,
          lat,
          lng,
          timeLabel: d.timestamp?.toDate ? d.timestamp.toDate().toLocaleTimeString() : "Just now",
          dateLabel: d.timestamp?.toDate ? d.timestamp.toDate().toLocaleDateString() : "Today",
        };
      });

      setAlerts(data);
      if (data.length > 0) {
        setMapCenter([data[0].lat, data[0].lng]);
      }
    });

    return () => unsubscribe();
  }, []);

  return (
    <div className="navigation-page">
      <header className="navigation-header">
        <h2>Navigation & Map</h2>
        <p>Live incident tracking and responder dispatch zone.</p>
      </header>

      <main className="navigation-content">
        {/* Map Section */}
        <div className="nav-card">
          <div className="map-header-top">
            <div className="zone-id">
              LIVE<br/>OPERATIONS<br/>ZONE<br/>MAP
            </div>
            <div className="map-badges">
              <span className="map-badge badge-users">Responders</span>
              <span className="map-badge badge-sos">SOS Alerts</span>
            </div>
          </div>

          <div className="live-map-area leaflet-integrated">
            <MapContainer
              center={mapCenter}
              zoom={13}
              style={{ height: "100%", width: "100%", borderRadius: "12px" }}
              zoomControl={false}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
                url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              />
              
              <MapAutoRecenter position={mapCenter} />

              {alerts.map((alert) => (
                <Marker 
                  key={alert.id} 
                  position={[alert.lat, alert.lng]}
                  icon={sosIcon}
                >
                  <Popup className="sos-popup">
                    <div className="popup-content">
                      <strong style={{color: '#ef4444'}}>🚨 ACTIVE SOS</strong>
                      <p><strong>User:</strong> {alert.senderName || "Anonymous"}</p>
                      <p><strong>Message:</strong> {alert.message}</p>
                      <p><strong>Time:</strong> {alert.timeLabel}</p>
                    </div>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </div>

          <div className="scroll-indicator">
            <button className="scroll-btn">↓</button>
          </div>
        </div>

        {/* Feed Section */}
        <div className="nav-card feed-card">
          <div className="feed-header">
            <h3>Recent SOS Alerts</h3>
            <div className="live-indicator">
              <div className="live-dot"></div> MONITORING
            </div>
          </div>

          <div className="hotspot-feed-list">
            {alerts.slice(0, 4).map((alert) => (
              <div key={alert.id} className="hotspot-item">
                <div className={`type-tag tag-robbery`}>SOS</div>
                <div className="item-info">
                  <h4>{alert.senderEmail || "Incident"}</h4>
                  <p>{alert.message}</p>
                </div>
                <div className="item-time">{alert.timeLabel}</div>
              </div>
            ))}
            {alerts.length === 0 && (
              <div className="empty-alerts">
                <p>No active SOS calls reported.</p>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

export default NavigationScreen;
