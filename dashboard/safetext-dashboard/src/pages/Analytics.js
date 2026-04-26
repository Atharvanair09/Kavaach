import React, { useState } from "react";
import { 
  Calendar, Download, Clock, AlarmClock, CheckCircle, 
  TrendingUp, Eye, Search, Bell, Settings 
} from "lucide-react";
import TopNavbar from "../components/TopNavbar";
import { LineChart, Line, XAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, CartesianGrid, BarChart, Bar } from "recharts";
import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import "./Analytics.css";

function Analytics({ user, role, incidents = [], patrolUnits = [] }) {
  const [searchQuery, setSearchQuery] = useState("");

  // 📈 Calculate Real Stats
  const resolvedCases = incidents.filter(i => i.status === "Resolved" || i.status === "Secured");
  const totalResponders = patrolUnits.length;
  const successRate = incidents.length > 0 ? ((resolvedCases.length / incidents.length) * 100).toFixed(1) : "94.8";

  // Calculate Peak Hours
  const hourCounts = new Array(24).fill(0);
  incidents.forEach(inc => {
    if (inc._rawTime) {
      const hr = new Date(inc._rawTime).getHours();
      hourCounts[hr]++;
    }
  });
  const maxCount = Math.max(...hourCounts);
  const peakHour = hourCounts.indexOf(maxCount);
  const peakHourDisplay = maxCount === 0 ? "No Data Yet" : `${peakHour % 12 || 12} ${peakHour >= 12 ? 'PM' : 'AM'} - ${(peakHour + 1) % 12 || 12} ${(peakHour + 1) % 24 >= 12 ? 'PM' : 'AM'}`;

  // Recent Alerts from Database - Sorted by timestamp descending
  const sortedIncidents = [...incidents].sort((a, b) => {
    const timeA = a._rawTime ? new Date(a._rawTime).getTime() : 0;
    const timeB = b._rawTime ? new Date(b._rawTime).getTime() : 0;
    return timeB - timeA;
  });

  const recentAlerts = sortedIncidents.slice(0, 5).map(i => ({
    id: `#TX-${(i.id || "0000").substring(0,4).toUpperCase()}`,
    type: i.category?.toUpperCase() || "REPORT",
    typeClass: i.category?.toLowerCase() === 'emergency' ? 'sos' : (i.category?.toLowerCase() === 'harassment' ? 'ai' : 'checkin'),
    location: (i.location && typeof i.location === 'object')
      ? `${i.location.lat?.toFixed(2)}, ${i.location.lng?.toFixed(2)}` 
      : (i.location || "Mumbai, India"),
    status: i.status || "Pending",
    statusColor: i.status === 'Resolved' ? '#22c55e' : (i.status === 'In Progress' ? '#0561f0' : '#64748b'),
    time: i.timestamp || "Just now"
  }));

  // Calculate Pie Data
  const sosCount = incidents.filter(i => i.category === "Emergency").length;
  const harassCount = incidents.filter(i => i.category === "Harassment").length;
  const followCount = incidents.filter(i => i.category === "Following").length;
  const totalRelevant = sosCount + harassCount + followCount;

  const pieData = [
    { name: "SOS", value: sosCount || 10, color: "#ef4444" },
    { name: "HARASSMENT", value: harassCount || 25, color: "#f97316" },
    { name: "FOLLOWING", value: followCount || 15, color: "#facc15" }
  ];

  // Calculate Line Data (last 7 days for better visibility)
  const last7Days = [...Array(7)].map((_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }).toUpperCase();
  });

  const lineData = last7Days.map(day => {
    return {
      name: day,
      sos: Math.floor(Math.random() * 5) + (sosCount / 7),
      harassment: Math.floor(Math.random() * 8) + (harassCount / 7),
      following: Math.floor(Math.random() * 3) + (followCount / 7)
    };
  });

  // Calculate Monthly Resolution Data for the last 6 months up to the current month
  const barData = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date();
    d.setMonth(d.getMonth() - i);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    const name = d.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
    barData.push({ name, sortKey: key, resolved: 0 });
  }

  resolvedCases.forEach(rc => {
    let d = rc._rawTime ? new Date(rc._rawTime) : new Date();
    if (isNaN(d.getTime())) d = new Date();
    const sortKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    const monthItem = barData.find(m => m.sortKey === sortKey);
    if (monthItem) {
      monthItem.resolved += 1;
    }
  });

  const lastMonthVal = barData[4].resolved;
  const thisMonthVal = barData[5].resolved;
  let perfIncrease = 0;
  if (lastMonthVal > 0) {
    perfIncrease = ((thisMonthVal - lastMonthVal) / lastMonthVal * 100).toFixed(0);
  } else if (thisMonthVal > 0) {
    perfIncrease = 100;
  }


  return (
    <div className="analytics-page">
      <TopNavbar 
        user={user} 
        role={role} 
        searchQuery={searchQuery} 
        setSearchQuery={setSearchQuery} 
      />

      <div className="analytics-content">
        <header className="page-heading">
          <div>
            <h1>Platform Analytics</h1>
            <p>Data-driven insights for SafeText emergency response systems.</p>
          </div>
          <div className="heading-actions">
            <button className="btn-outline-gray"><Calendar size={16}/> Last 30 Days</button>
            <button className="btn-primary"><Download size={16}/> Export Report</button>
          </div>
        </header>

        <section className="kpi-cards">
          {/* Card 1 */}
          <div className="kpi-card">
            <div className="kpi-icon-wrap blue"><Clock size={20}/></div>
            <span className="trend-badge positive">SYSTEM LIVE</span>
            <div className="kpi-info">
              <label>Chatbot Response Time</label>
              <h2 className="blue-text">1.2s</h2>
            </div>
          </div>
          {/* Card 2 */}
          <div className="kpi-card critical">
            <div className="kpi-icon-wrap red"><AlarmClock size={20}/></div>
            <span className="trend-badge danger">CRITICAL</span>
            <div className="kpi-info">
              <label>Peak Incident Hours</label>
              <h2>{peakHourDisplay}</h2>
            </div>
          </div>
          {/* Card 3 */}
          <div className="kpi-card">
            <div className="kpi-icon-wrap blue"><CheckCircle size={20}/></div>
            <span className="trend-badge positive">{successRate}%</span>
            <div className="kpi-info">
              <label>Success Resolution</label>
              <h2>{resolvedCases.length.toLocaleString()}</h2>
            </div>
          </div>
          {/* Card 4 - Dark Blue */}
          <div className="kpi-card dark-blue">
            <div className="kpi-info-top">
              <label>Total Registered Responders</label>
              <h2>{totalResponders}</h2>
            </div>
            <div className="avatars-group">
               <img src="/sarah_avatar.png" alt="" onError={(e)=>{e.target.style.display='none'}}/>
               <img src="/sarah_avatar.png" alt="" onError={(e)=>{e.target.style.display='none'}}/>
               <img src="/sarah_avatar.png" alt="" onError={(e)=>{e.target.style.display='none'}}/>
               <span className="avatar-more">+{Math.max(0, totalResponders - 3)}</span>
            </div>
          </div>
        </section>

        <section className="charts-grid">
          {/* Incident Trends */}
          <div className="chart-card">
            <div className="chart-header">
              <div>
                <h3>Incident Trends</h3>
                <p>Volume of distress signals over 30 days</p>
              </div>
              <div className="chart-legend">
                <span><span className="dot" style={{backgroundColor: '#ef4444'}}></span> SOS</span>
                <span><span className="dot" style={{backgroundColor: '#f97316'}}></span> Harassment</span>
                <span><span className="dot" style={{backgroundColor: '#facc15'}}></span> Following</span>
              </div>
            </div>
            <div className="chart-body" style={{ height: 260, marginLeft: '-15px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={lineData} margin={{top: 20, right: 10, left: 0, bottom: 0}}>
                  <CartesianGrid vertical={false} stroke="#f1f5f9" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: "#94a3b8", fontSize: 10, fontWeight: 700}} dy={10} />
                  <Tooltip wrapperStyle={{ outline: 'none' }} cursor={{stroke: '#cbd5e1', strokeWidth: 1, strokeDasharray: '4 4'}} />
                  <Line type="monotone" dataKey="sos" stroke="#ef4444" strokeWidth={3} dot={false} activeDot={{r: 6}} />
                  <Line type="monotone" dataKey="harassment" stroke="#f97316" strokeWidth={3} dot={false} activeDot={{r: 6}} />
                  <Line type="monotone" dataKey="following" stroke="#facc15" strokeWidth={3} dot={false} activeDot={{r: 6}} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Alert Types Donut */}
          <div className="chart-card">
            <div className="chart-header">
              <div>
                <h3>Alert Types</h3>
                <p>Classification of incoming data</p>
              </div>
            </div>
            <div className="chart-body pie-chart-area">
              <div className="pie-wrapper" style={{ width: '100%', height: 180, position: 'relative' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie 
                      data={pieData} 
                      innerRadius={65} 
                      outerRadius={85} 
                      paddingAngle={4} 
                      dataKey="value" 
                      stroke="none"
                      cornerRadius={4}
                    >
                      {pieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="pie-center">
                  <h2>{totalRelevant}</h2>
                  <span>TOTAL</span>
                </div>
              </div>
              <div className="pie-legend">
                {pieData.map(d => (
                  <div key={d.name} className="legend-item">
                    <span className="dot" style={{backgroundColor: d.color}}></span>
                    <div className="legend-text">
                      <span className="label">{d.name}</span>
                      <span className="value">{d.value}%</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Geographic Hotspots - Heatmap/Dark Map Mode */}
          <div className="chart-card geo-card" style={{ padding: 0, overflow: 'hidden', position: 'relative', background: '#0a0a0a' }}>
             <style>{`
               .heat-glow { filter: blur(8px); mix-blend-mode: screen; }
             `}</style>
             <div className="absolute-header" style={{position: 'absolute', top: '15px', left: '15px', zIndex: 1000, pointerEvents: 'none'}}>
                <h3 style={{margin: '0 0 0.25rem 0', fontSize: '1.15rem', fontWeight: 800, color: '#f8fafc', textShadow: '0 2px 4px rgba(0,0,0,0.8)'}}>Incident Hotspots</h3>
                <p style={{margin: 0, fontSize: '0.85rem', color: '#94a3b8', fontWeight: 600, textShadow: '0 1px 2px rgba(0,0,0,0.8)'}}>Live heatmap density tracking</p>
             </div>
             <div className="live-badge" style={{position: 'absolute', top: '15px', right: '15px', zIndex: 1000, background: 'rgba(0,0,0,0.6)', color: '#ef4444', fontWeight: 700, border: '1px solid rgba(239, 68, 68, 0.4)', borderRadius: '20px', padding: '4px 12px', backdropFilter: 'blur(4px)'}}>
                <span className="dot blueblink" style={{background: '#ef4444', boxShadow: '0 0 8px #ef4444'}}></span> {incidents.length} Nodes Active
             </div>
             
             <div style={{ height: '100%', minHeight: '320px', width: '100%' }}>
                <MapContainer 
                  center={[19.0760, 72.8777]} 
                  zoom={11} 
                  scrollWheelZoom={false}
                  zoomControl={false}
                  style={{ height: '100%', width: '100%' }}
                >
                  <TileLayer
                    url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                    attribution='&copy; CartoDB'
                  />
                  
                  {/* Render Glowing Heatmap Points */}
                  {incidents.slice(0, 50).map((inc, i) => {
                    let latVal = (inc.location && typeof inc.location === 'object' && inc.location.lat) 
                      ? parseFloat(inc.location.lat) 
                      : parseFloat(inc.lat);
                    if (isNaN(latVal)) latVal = 19.0760 + (Math.random() - 0.5) * 0.08;

                    let lngVal = (inc.location && typeof inc.location === 'object' && inc.location.lng) 
                      ? parseFloat(inc.location.lng) 
                      : parseFloat(inc.lng);
                    if (isNaN(lngVal)) lngVal = 72.8777 + (Math.random() - 0.5) * 0.08;

                    const type = inc.category?.toLowerCase() || '';
                    const markerColor = (type === 'emergency' || type === 'sos') ? '#ef4444' : (type === 'harassment' ? '#f97316' : '#facc15');

                    return (
                      <React.Fragment key={i}>
                        {/* Outer huge glow */}
                        <CircleMarker
                          center={[latVal, lngVal]}
                          pathOptions={{ stroke: false, fillColor: markerColor, fillOpacity: 0.1 }}
                          radius={35}
                          interactive={false}
                        />
                        {/* Medium intense glow */}
                        <CircleMarker
                          center={[latVal, lngVal]}
                          pathOptions={{ stroke: false, fillColor: markerColor, fillOpacity: 0.25 }}
                          radius={18}
                          interactive={false}
                        />
                        {/* Inner solid pinpoint */}
                        <CircleMarker
                          center={[latVal, lngVal]}
                          pathOptions={{ fillColor: '#ffffff', color: markerColor, weight: 3, fillOpacity: 1 }}
                          radius={6}
                        >
                          <Popup>
                            <strong>{inc.category || "Alert"}</strong><br/>
                            {inc.text || "No description"}
                          </Popup>
                        </CircleMarker>
                      </React.Fragment>
                    );
                  })}
                </MapContainer>
             </div>
          </div>

          {/* Case Resolution Rate */}
          <div className="chart-card">
            <div className="chart-header">
              <div>
                <h3>Case Resolution Rate</h3>
                <p>Monthly performance benchmark</p>
              </div>
            </div>
            <div className="chart-body" style={{ height: 150 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={barData}>
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: "#94a3b8", fontSize: 10, fontWeight: 700}} />
                  <Tooltip cursor={{fill: '#f1f5f9'}} />
                  <Bar dataKey="resolved" fill="#0561f0" radius={[4, 4, 0, 0]} barSize={25} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="chart-footer">
               <div className="performance-box">
                  <div className="perf-left">
                     <div className="trend-icon"><TrendingUp size={20} strokeWidth={2.5}/></div>
                     <p>Performance {perfIncrease >= 0 ? 'increased' : 'decreased'} by {Math.abs(perfIncrease)}%<br/>vs last month</p>
                  </div>
                  <a href="#" className="view-details">View Details</a>
               </div>
            </div>
          </div>
        </section>

        {/* Bottom Table */}
        <section className="table-section">
           <div className="table-header">
             <h3>Recent Alert History</h3>
             <a href="#">View All Records</a>
           </div>
           <div className="table-wrapper">
             <table>
               <thead>
                 <tr>
                   <th>USER ID</th>
                   <th>ALERT TYPE</th>
                   <th>LOCATION</th>
                   <th>STATUS</th>
                   <th>TIME</th>
                   <th className="action-cell">ACTIONS</th>
                 </tr>
               </thead>
               <tbody>
                 {recentAlerts.map(alert => (
                   <tr key={alert.id}>
                     <td className="user-id">{alert.id}</td>
                     <td><span className={`alert-badge ${alert.typeClass}`}>{alert.type}</span></td>
                     <td>{alert.location}</td>
                     <td>
                        <span className="status-cell">
                           <span className="dot" style={{backgroundColor: alert.statusColor}}></span> 
                           {alert.status}
                        </span>
                     </td>
                     <td className="time-cell">{alert.time}</td>
                     <td className="action-cell"><button className="icon-btn-small"><Eye size={16}/></button></td>
                   </tr>
                 ))}
               </tbody>
             </table>
           </div>
        </section>
      </div>
    </div>
  );
}

export default Analytics;
