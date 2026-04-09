import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Lock, Mail, User, ShieldCheck, Briefcase } from "lucide-react";
import { db } from "../services/firebase";
import { collection, addDoc, serverTimestamp } from "firebase/firestore";

function Auth({ onLogin }) {
  const [isLogin, setIsLogin] = useState(true);
  const [role, setRole] = useState("admin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const navigate = useNavigate();

  const handleSubmit = (e) => {
    e.preventDefault();
    // Mock Auth logic
    const user = { name: name || email.split("@")[0], email, id: Math.random().toString(36).substr(2, 9) };
    
    // Log Activity to Firebase Audit Log
    try {
      addDoc(collection(db, "audit_logs"), {
        action: isLogin ? "Login" : "Registration",
        details: `${isLogin ? "Successful login" : "New account created"} by ${user.name} (${role})`,
        ip: "Client " + Math.floor(Math.random() * 255) + "." + Math.floor(Math.random() * 255) + ".1.1", // Realistic mock IP
        timestamp: serverTimestamp(),
        userId: user.id
      });
    } catch (err) {
      console.error("Error logging audit event:", err);
    }

    onLogin(user, role);
    navigate(role === "admin" ? "/" : "/dashboard");
  };

  return (
    <div className="auth-container center-content">
      <div className="card auth-card">
        <div className="auth-header">
          <div className="auth-icon-badge">
            <Lock size={24} />
          </div>
          <h2>{isLogin ? "Welcome Back" : "Create Account"}</h2>
          <p className="subtitle">
            {isLogin 
              ? "Access the SafeText monitoring portal" 
              : "Join the emergency response network"}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form">
          {!isLogin && (
            <div className="form-group">
              <label><User size={16} /> Full Name</label>
              <input 
                type="text" 
                className="form-control" 
                placeholder="John Doe" 
                value={name}
                onChange={(e) => setName(e.target.value)}
                required 
              />
            </div>
          )}

          <div className="form-group">
            <label><Mail size={16} /> Email Address</label>
            <input 
              type="email" 
              className="form-control" 
              placeholder="name@example.com" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required 
            />
          </div>

          <div className="form-group">
            <label><Lock size={16} /> Password</label>
            <input 
              type="password" 
              className="form-control" 
              placeholder="••••••••" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required 
            />
          </div>

          <div className="role-selector">
            <label className="role-label-main">Select Your Role</label>
            <div className="role-options">
              <button 
                type="button" 
                className={`role-btn ${role === "admin" ? "active" : ""}`}
                onClick={() => setRole("admin")}
              >
                <ShieldCheck size={20} />
                <span>Admin</span>
              </button>
              <button 
                type="button" 
                className={`role-btn ${role === "patrol" ? "active" : ""}`}
                onClick={() => setRole("patrol")}
              >
                <Briefcase size={20} />
                <span>Crime Patrol</span>
              </button>
            </div>
          </div>

          <button type="submit" className="btn btn-primary btn-block btn-lg">
            {isLogin ? "Sign In" : "Register"}
          </button>
        </form>

        <div className="auth-footer">
          <p>
            {isLogin ? "New to SafeText?" : "Already have an account?"}
            <button 
              className="btn-link" 
              onClick={() => setIsLogin(!isLogin)}
            >
              {isLogin ? " Create an account" : " Login here"}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}

export default Auth;
