import React from "react";
import { Link } from "react-router-dom";
import { Phone, Globe, Shield, HeartPulse, Scale, AlertCircle, Home } from "lucide-react";

function ResourceList() {
  const resourceCategories = [
    {
      title: "Emergency Numbers",
      icon: AlertCircle,
      color: "danger",
      items: [
        { name: "National Emergency Helpline", number: "112", icon: Phone },
        { name: "Women's Safety Helpline", number: "1091", icon: Phone },
        { name: "Domestic Abuse Hotline", number: "181", icon: Phone },
      ],
    },
    {
      title: "Medical Assistance",
      icon: HeartPulse,
      color: "success",
      items: [
        { name: "Emergency Ambulance", number: "108 / 102", icon: Phone },
        { name: "National Blood Bank", number: "1910", icon: Phone },
      ],
    },
    {
      title: "Legal & Protection",
      icon: Scale,
      color: "primary",
      items: [
        { name: "Free Legal Aid", number: "15100", icon: Phone },
        { name: "Child Helpline", number: "1098", icon: Phone },
      ],
    },
    {
      title: "Digital Support",
      icon: Globe,
      color: "secondary",
      items: [
        { name: "Cyber Crime Reporting", number: "1930", icon: Phone },
        { name: "NCW Official Website", number: "Visit ncw.nic.in", icon: Globe },
      ],
    },
  ];

  return (
    <div className="page-container">
      <header className="resources-header flex-header">
        <div className="header-text">
          <h1>Safety Support Directory</h1>
          <p className="subtitle">Quick access to essential helplines and supportive resources.</p>
        </div>
        <Link to="/" className="btn btn-outline btn-sm back-btn">
          <Home size={18} />
          <span>Back to Home</span>
        </Link>
      </header>

      <div className="resources-masonry">
        {resourceCategories.map((category, idx) => (
          <div key={idx} className="card resource-category-card">
            <div className={`category-header ${category.color}`}>
              <category.icon size={24} />
              <h3>{category.title}</h3>
            </div>
            <div className="category-items">
              {category.items.map((item, i) => (
                <div key={i} className="resource-item">
                  <div className="resource-info">
                    <item.icon size={16} className="muted-icon" />
                    <span>{item.name}</span>
                  </div>
                  <span className="resource-number">{item.number}</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="card tip-card">
        <Shield className="tip-icon primary" />
        <div className="tip-content">
          <h3>Stay Safe Tip</h3>
          <p>Always keep your phone charged and enable emergency SOS shortcuts in your device settings. Share your live location with trusted contacts whenever traveling alone or at night.</p>
        </div>
      </div>
    </div>
  );
}

export default ResourceList;