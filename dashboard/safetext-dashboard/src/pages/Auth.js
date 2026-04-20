import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Lock, Mail, User, ShieldCheck, Briefcase } from "lucide-react";
import { db, auth, googleProvider } from "../services/firebase";
import { collection, addDoc, serverTimestamp, getDocs, query, where } from "firebase/firestore";
import { signInWithPopup, signOut } from "firebase/auth";

function Auth({ onLogin }) {
  const [role, setRole] = useState("admin");
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  const handleGoogleLogin = async () => {
    setError(null);
    try {
      const result = await signInWithPopup(auth, googleProvider);
      const email = result.user.email;

      // 🛑 CHECK: Is this user already signed up via the mobile app?
      // Mobile app users are stored in the "users" collection.
      const userQuery = query(collection(db, "users"), where("email", "==", email));
      const querySnapshot = await getDocs(userQuery);

      if (!querySnapshot.empty) {
        // User found in "users" collection (mobile app user)
        await signOut(auth); // Sign them out from Firebase
        setError("Access Denied: This account is registered as a User. Dashboard access is restricted to Admin/Patrol personnel.");
        return;
      }

      const user = {
        name: result.user.displayName,
        email: result.user.email,
        id: result.user.uid,
        photo: result.user.photoURL
      };

      // Log Activity to Firebase Audit Log
      await addDoc(collection(db, "audit_logs"), {
        action: "Google Login",
        details: `Successful Google login by ${user.name} (${role})`,
        ip: "Client " + Math.floor(Math.random() * 255) + "." + Math.floor(Math.random() * 255) + ".1.1",
        timestamp: serverTimestamp(),
        userId: user.id
      });

      onLogin(user, role);
      navigate(role === "admin" ? "/" : "/dashboard");
    } catch (error) {
      console.error("Error during Google Login:", error);
      setError("An error occurred during authentication. Please try again.");
    }
  };

  return (
    <div className="auth-container center-content">
      <div className="card auth-card">
        <div className="auth-header">
          <div className="auth-icon-badge">
            <Lock size={24} />
          </div>
          <h2>Sign In to SafeText</h2>
          <p className="subtitle">
            Access the secure environmental & public safety portal
          </p>
        </div>

        {error && (
          <div className="auth-error-panel">
            <p>{error}</p>
          </div>
        )}

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

        <button 
          onClick={handleGoogleLogin} 
          className="btn btn-primary btn-block google-btn-large"
        >
          <img 
            src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg" 
            alt="Google" 
            width="20" 
            style={{ filter: "brightness(0) invert(1)" }}
          />
          <span>Continue with Google</span>
        </button>

        <div className="auth-footer">
          <p className="text-muted text-xs">
            By signing in, you agree to our terms of service and security protocols.
          </p>
        </div>
      </div>
    </div>
  );
}

export default Auth;
