import React from "react";
import { Search, Bell, Settings } from "lucide-react";

function TopNavbar({ user, role, searchQuery, setSearchQuery }) {
  return (
    <nav className="top-nav">
      <div className="search-container">
        <Search className="search-icon" size={18} />
        <input
          type="text"
          className="search-input"
          placeholder="Search incidents, users, or tags..."
          value={searchQuery}
          onChange={(e) => setSearchQuery && setSearchQuery(e.target.value)}
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
            <span className="user-name">{user?.name || "Kavaach User"}</span>
            <span className="user-role">
              {role === "admin" ? "Senior Admin" : "Crime Patrol"}
            </span>
          </div>
          <img
            src={user?.photo || `https://ui-avatars.com/api/?name=${user?.name || "User"}&background=3b82f6&color=fff`}
            alt="Avatar"
            className="user-avatar"
            onError={(e) => { e.target.src = `https://ui-avatars.com/api/?name=${user?.name || "User"}&background=3b82f6&color=fff` }}
            referrerPolicy="no-referrer"
          />
        </div>
      </div>
    </nav>
  );
}

export default TopNavbar;
