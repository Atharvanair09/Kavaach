import React, { useState } from "react";
import { 
  Calendar, Download, Clock, AlarmClock, CheckCircle, 
  TrendingUp, Eye, Search, Bell, Settings 
} from "lucide-react";
import TopNavbar from "../components/TopNavbar";
import { LineChart, Line, XAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, CartesianGrid } from "recharts";
import "./Analytics.css";

function Analytics({ user, role }) {
  const [searchQuery, setSearchQuery] = useState("");

  const lineData = [
    { name: "AUG 01", sos: 10, checkin: 50 },
    { name: "AUG 07", sos: 35, checkin: 40 },
    { name: "AUG 14", sos: 15, checkin: 60 },
    { name: "AUG 21", sos: 75, checkin: 55 },
    { name: "AUG 30", sos: 20, checkin: 65 }
  ];

  const pieData = [
    { name: "AI FLAG", value: 42, color: "#0561f0" },
    { name: "CHECK-IN", value: 40, color: "#e2e8f0" },
    { name: "SOS", value: 18, color: "#e11d48" }
  ];

  const recentAlerts = [
    { id: "#TX-8821", type: "SOS TRIGGER", typeClass: "sos", location: "Brooklyn, NY", status: "Active Dispatch", statusColor: "#0561f0", time: "2 mins ago" },
    { id: "#TX-8819", type: "AI FLAG", typeClass: "ai", location: "Queens, NY", status: "Pending Review", statusColor: "#64748b", time: "14 mins ago" },
    { id: "#TX-8815", type: "CHECK-IN", typeClass: "checkin", location: "Manhattan, NY", status: "Resolved", statusColor: "#22c55e", time: "45 mins ago" }
  ];

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
            <span className="trend-badge positive">+12%</span>
            <div className="kpi-info">
              <label>Avg Response Time</label>
              <h2 className="blue-text">4.2m</h2>
            </div>
          </div>
          {/* Card 2 */}
          <div className="kpi-card critical">
            <div className="kpi-icon-wrap red"><AlarmClock size={20}/></div>
            <span className="trend-badge danger">CRITICAL</span>
            <div className="kpi-info">
              <label>Peak Incident Hours</label>
              <h2>9 PM - 2 AM</h2>
            </div>
          </div>
          {/* Card 3 */}
          <div className="kpi-card">
            <div className="kpi-icon-wrap blue"><CheckCircle size={20}/></div>
            <span className="trend-badge positive">94.8%</span>
            <div className="kpi-info">
              <label>Success Resolution</label>
              <h2>1,242</h2>
            </div>
          </div>
          {/* Card 4 - Dark Blue */}
          <div className="kpi-card dark-blue">
            <div className="kpi-info-top">
              <label>Total Active Responders</label>
              <h2>158</h2>
            </div>
            <div className="avatars-group">
               <img src="/sarah_avatar.png" alt="" onError={(e)=>{e.target.style.display='none'}}/>
               <img src="/sarah_avatar.png" alt="" onError={(e)=>{e.target.style.display='none'}}/>
               <img src="/sarah_avatar.png" alt="" onError={(e)=>{e.target.style.display='none'}}/>
               <span className="avatar-more">+155</span>
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
                <span><span className="dot blue"></span> SOS Alerts</span>
                <span><span className="dot gray"></span> Proactive Checks</span>
              </div>
            </div>
            <div className="chart-body" style={{ height: 260, marginLeft: '-15px' }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={lineData} margin={{top: 20, right: 10, left: 0, bottom: 0}}>
                  <CartesianGrid vertical={false} stroke="#f1f5f9" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: "#94a3b8", fontSize: 10, fontWeight: 700}} dy={10} />
                  <Tooltip wrapperStyle={{ outline: 'none' }} cursor={{stroke: '#cbd5e1', strokeWidth: 1, strokeDasharray: '4 4'}} />
                  <Line type="monotone" dataKey="sos" stroke="#0561f0" strokeWidth={3} dot={false} activeDot={{r: 6}} />
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
                  <h2>3.8k</h2>
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

          {/* Geographic Hotspots */}
          <div className="chart-card geo-card">
             <div className="geo-map">
                <style>{`
                  .geo-bg {
                    width: 100%; height: 100%;
                    background: radial-gradient(circle at 40% 40%, rgba(255,255,255,0.8) 0%, transparent 40%),
                                radial-gradient(circle at 60% 60%, rgba(0,0,0,0.1) 0%, transparent 50%);
                    background-size: 60px 60px;
                    opacity: 0.8;
                    position: absolute;
                    top: 0; left: 0;
                  }
                  .geo-dots {
                    position: absolute;
                    width: 12px; height: 12px;
                    background: #0f172a;
                    border-radius: 50%;
                    box-shadow: 0 0 0 4px rgba(15,23,42,0.2);
                  }
                `}</style>
                <div className="absolute-header" style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
                  <div>
                    <h3 style={{margin: '0 0 0.25rem 0', fontSize: '1.15rem', fontWeight: 800}}>Geographic Hotspots</h3>
                    <p style={{margin: 0, color: '#64748b', fontSize: '0.85rem'}}>Real-time distress signal density</p>
                  </div>
                  <div className="live-badge"><span className="dot blueblink"></span> Live Monitoring</div>
                </div>
                
                {/* Simulated topo map via an image */}
                <img src="/map_placeholder.png" alt="Map" style={{width: '100%', height:'100%', objectFit: 'cover', opacity: 0.5}} 
                     onError={(e) => { e.target.style.display='none'; e.target.parentElement.style.background = 'radial-gradient(circle at 50% 50%, #aaaaaa, #e2e8f0)'}} />
                
                <div className="geo-bg">
                   {/* Abstract representation of map hotspots */}
                   <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" style={{position: 'absolute'}}>
                      <filter id="blur"><feGaussianBlur stdDeviation="10" /></filter>
                      <circle cx="30%" cy="40%" r="60" fill="rgba(0,0,0,0.15)" filter="url(#blur)" />
                      <circle cx="70%" cy="60%" r="80" fill="rgba(0,0,0,0.2)" filter="url(#blur)" />
                      <circle cx="50%" cy="80%" r="50" fill="rgba(0,0,0,0.1)" filter="url(#blur)" />
                      <path d="M 0,50 Q 80,10 150,60 T 350,70 T 500,40" stroke="rgba(0,0,0,0.08)" strokeWidth="30" fill="none" filter="url(#blur)" />
                      <path d="M 50,150 Q 180,90 250,160 T 450,170 T 600,140" stroke="rgba(0,0,0,0.12)" strokeWidth="50" fill="none" filter="url(#blur)" />
                   </svg>
                </div>
                <div className="geo-dots" style={{top: '45%', left: '32%'}}></div>
                <div className="geo-dots" style={{top: '65%', left: '68%'}}></div>
                <div style={{width: 16, height: 16, top: '80%', left: '45%', position: 'absolute', background: '#0f172a', borderRadius: '50%', boxShadow: '0 0 0 6px rgba(15,23,42,0.3)'}}></div>
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
            <div className="chart-body" style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', paddingTop: '20px'}}>
               <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', padding: '0 10px' }}>
                 <span className="x-label">MAR</span>
                 <span className="x-label">APR</span>
                 <span className="x-label">MAY</span>
                 <span className="x-label blue">JUN</span>
                 <span className="x-label">JUL</span>
                 <span className="x-label">AUG</span>
               </div>
               <div className="performance-box">
                  <div className="perf-left">
                     <div className="trend-icon"><TrendingUp size={20} strokeWidth={2.5}/></div>
                     <p>Performance increased by 4%<br/>vs last month</p>
                  </div>
                  <a href="#" className="view-details">View<br/>Details</a>
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
