import React, { useState,  useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Shield } from "lucide-react";
import "./App.css";
import { db, createNotification } from "./services/firebase";
import { collection, addDoc, updateDoc, setDoc, doc, serverTimestamp, query, orderBy, onSnapshot } from "firebase/firestore";

import Home from "./pages/Home";
import ResourceList from "./components/ResourceList";
import Emergency from "./pages/Emergency";

import Navbar from "./components/Navbar";
import Dashboard from "./pages/Dashboard";
import Auth from "./pages/Auth";
import Analytics from "./pages/Analytics";
import ChatMonitor from "./pages/ChatMonitor";
import Responders from "./pages/Responders";
import Notifications from "./pages/Notifications";
import AuditLog from "./pages/AuditLog";

import StatusSafety from "./pages/patrol/StatusSafety";
import PatrolIncidents from "./pages/patrol/PatrolIncidents";
import NavigationScreen from "./pages/patrol/NavigationScreen";
import Communication from "./pages/patrol/Communication";
import MyStats from "./pages/patrol/MyStats";

function App() {
  const [currentUser, setCurrentUser] = useState(() => {
    const saved = localStorage.getItem("user");
    return saved ? JSON.parse(saved) : null;
  });

  const [role, setRole] = useState(() => {
    return localStorage.getItem("role") || null;
  });

  const [unitStatuses, setUnitStatuses] = useState({});

  const rawUnits = [
    { id: "P1", name: "Alpha Unit", status: "Active", location: "Downtown" },
    { id: "P2", name: "Delta Patrol", status: "Active", location: "West Side" },
    { id: "P3", name: "Rapid Response 1", status: "Active", location: "South Hub" },
  ];

  // Merge static unit info with live Firestore status
  const patrolUnits = rawUnits.map(unit => ({
    ...unit,
    availability: unitStatuses[unit.id] || "active"
  }));

  const [incidents, setIncidents] = useState([]);

  const [hasNewIncident, setHasNewIncident] = useState(false);

  // --- Live Status Synchronization ---
  useEffect(() => {
    const q = query(collection(db, "unit_status"));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const statuses = {};
      snapshot.docs.forEach(doc => {
        statuses[doc.id] = doc.data().status;
      });
      setUnitStatuses(statuses);
    });
    return () => unsubscribe();
  }, []);

  const updateUnitStatus = async (unitId, status) => {
    try {
      await setDoc(doc(db, "unit_status", unitId), {
        status,
        timestamp: serverTimestamp()
      }, { merge: true });
    } catch (error) {
      console.error("Error updating unit status:", error);
    }
  };

  // 🔎 Improved Classification Logic
  const classifyIncident = (text) => {
    const lower = text.toLowerCase();

    // 🔴 HIGH PRIORITY (Violence / Attack / Immediate Threat)
    if (
      lower.includes("danger") ||
      lower.includes("emergency") ||
      lower.includes("attack") ||
      lower.includes("attacking") ||
      lower.includes("hit") ||
      lower.includes("hitting") ||
      lower.includes("assault") ||
      lower.includes("violence")
    ) {
      return { intent: "Emergency", priority: "High", color: "red" };
    }

    // 🟠 MEDIUM PRIORITY (Medical Help)
    if (
      lower.includes("injured") ||
      lower.includes("doctor") ||
      lower.includes("medical") ||
      lower.includes("bleeding")
    ) {
      return { intent: "Medical", priority: "Medium", color: "orange" };
    }

    // 🟡 NORMAL PRIORITY (Harassment / Stalking)
    if (
      lower.includes("harass") ||
      lower.includes("stalk") ||
      lower.includes("threat")
    ) {
      return { intent: "Harassment", priority: "Normal", color: "gold" };
    }

    // ⚪ LOW PRIORITY (General Queries)
    return { intent: "General", priority: "Low", color: "gray" };
  };

  // ➕ Add Incident
  const addIncident = async (text) => {
    console.log("Incident received:", text);
    const classification = classifyIncident(text);

    try {
      // 1. Save to Firestore
      const docRef = await addDoc(collection(db, "incidents"), {
        message: text,
        category: classification.intent,
        threat_level: classification.priority.toUpperCase(),
        status: "Pending",
        timestamp: serverTimestamp(),
        location: "Detected Location" // Mock
      });

      // 2. Create Notification
      createNotification(
        classification.priority === "High" ? "alert" : "info",
        `New ${classification.priority} priority incident reported: ${classification.intent}`
      );

      setHasNewIncident(true);
    } catch (error) {
      console.error("Error adding incident:", error);
    }
  };

  // 🔄 Update Incident Status
  const updateStatus = async (incidentId, newStatus) => {
    try {
      const incidentRef = doc(db, "incidents", incidentId);
      const updateData = { status: newStatus };
      
      // Find the unit name for the notification (lookup before potentially clearing)
      const incident = incidents.find(i => i.id === incidentId);
      const unitName = patrolUnits.find(p => p.id === incident?.assignedTo)?.name || "A patrol unit";

      // If rejected, set it to explicitly 'Rejected' and preserve assignment info for records
      if (newStatus === "Pending") {
        updateData.status = "Rejected";
      }

      await updateDoc(incidentRef, updateData);

      // --- Notification Logic ---
      if (newStatus === "Resolved") {
        createNotification("success", `Incident Resolved: Case ${incidentId.substring(0, 5)} has been secured.`);
      } else if (newStatus === "Pending") {
        createNotification("info", `Case Rejected: Unit ${unitName} has declined Case #${incidentId.substring(0, 5)} and returned it to queue.`);
      } else if (newStatus === "In Progress") {
        createNotification("info", `Assignment Accepted: Case #${incidentId.substring(0, 5)} is now being handled by ${unitName}.`);
      }
    } catch (error) {
      console.error("Error updating status:", error);
    }
  };

  // 👮 Assign Patrol
  const assignPatrol = async (incidentId, patrolId) => {
    try {
      const incidentRef = doc(db, "incidents", incidentId);
      await updateDoc(incidentRef, {
        assignedTo: patrolId,
        status: "In Progress"
      });

      const unitName = patrolUnits.find(p => p.id === patrolId)?.name || "Responder";
      createNotification("info", `Patrol assigned: ${unitName} is responding to Case ${incidentId.substring(0, 5)}`);
    } catch (error) {
      console.error("Error assigning patrol:", error);
    }
  };

  // ➕ Add Manual Incident (from Responders Panel)
  const addManualIncident = async (unitId, text) => {
    try {
      const docRef = await addDoc(collection(db, "incidents"), {
        message: text,
        category: "Dispatch",
        threat_level: "HIGH",
        status: "Pending",
        assignedTo: unitId,
        timestamp: serverTimestamp(),
        location: "Direct Dispatch"
      });

      const unitName = patrolUnits.find(p => p.id === unitId)?.name || "Responder";
      createNotification("info", `Manual task assigned to ${unitName}: "${text}"`);
      return docRef.id;
    } catch (error) {
      console.error("Error adding manual incident:", error);
    }
  };

  useEffect(() => {
    const q = query(collection(db, "incidents"), orderBy("timestamp", "desc"));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        text: doc.data().message,
        intent: doc.data().category,
        priority: doc.data().threat_level?.charAt(0).toUpperCase() + doc.data().threat_level?.slice(1).toLowerCase() || "Low",
        timestamp: doc.data().timestamp?.toDate 
          ? doc.data().timestamp.toDate().toLocaleTimeString() 
          : new Date().toLocaleTimeString()
      }));
      setIncidents(data);
    });
    return () => unsubscribe();
  }, []);

  // 🔐 Auth Actions
  const handleLogin = (user, userRole) => {
    setCurrentUser(user);
    setRole(userRole);
    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("role", userRole);
  };

  const handleLogout = () => {
    setCurrentUser(null);
    setRole(null);
    localStorage.removeItem("user");
    localStorage.removeItem("role");
  };

  useEffect(() => {
    localStorage.setItem("incidents", JSON.stringify(incidents));
  }, [incidents]);

  const ProtectedRoute = ({ children, allowedRole = null }) => {
    if (!currentUser) return <Navigate to="/" />;
    if (allowedRole && role !== allowedRole) return <Navigate to="/" />;
    return children;
  };

  return (
    <BrowserRouter>
    <div className="app-main">
      {currentUser && (
        <Navbar
          hasNewIncident={hasNewIncident}
          clearNotification={() => setHasNewIncident(false)}
          user={currentUser}
          role={role}
          handleLogout={handleLogout}
        />
      )}

      <main className="main-content">
        {currentUser && role && (
          <header className={`panel-top-header ${role}-theme`}>
            <Shield size={20} className="panel-header-icon" />
            <h2>{role === "admin" ? "Admin Security Panel" : "Crime Patrol Interface"}</h2>
            <span className={`badge-role badge-role-${role}`}>
              {role === "admin" ? "Administrator" : "Patrol Unit"}
            </span>
          </header>
        )}
        <Routes>

        <Route
          path="/"
          element={
            currentUser ? (
              <Navigate to="/dashboard" />
            ) : (
              <Home user={currentUser} role={role} handleLogout={handleLogout} incidents={incidents} patrolUnits={patrolUnits} />
            )
          }
        />

        <Route path="/auth" element={<Auth onLogin={handleLogin} />} />

        <Route
          path="/resources"
          element={
            <ProtectedRoute>
              <ResourceList />
            </ProtectedRoute>
          }
        />

        <Route path="/analytics" element={<ProtectedRoute allowedRole="admin"><Analytics /></ProtectedRoute>} />
        <Route path="/chat" element={<ProtectedRoute allowedRole="admin"><ChatMonitor /></ProtectedRoute>} />
        <Route path="/responders" element={
          <ProtectedRoute>
            <Responders 
              patrolUnits={patrolUnits} 
              incidents={incidents} 
              assignPatrol={assignPatrol}
              addManualIncident={addManualIncident}
              updateStatus={updateStatus}
              updateUnitStatus={updateUnitStatus}
              role={role}
            />
          </ProtectedRoute>
        } />
        <Route path="/notifications" element={<ProtectedRoute allowedRole="admin"><Notifications /></ProtectedRoute>} />
        <Route path="/audit-log" element={<ProtectedRoute allowedRole="admin"><AuditLog /></ProtectedRoute>} />

        <Route path="/patrol/status" element={<ProtectedRoute allowedRole="patrol"><StatusSafety incidents={incidents} patrolUnits={patrolUnits} /></ProtectedRoute>} />
        <Route path="/patrol/incidents" element={<ProtectedRoute allowedRole="patrol"><PatrolIncidents incidents={incidents} updateStatus={updateStatus} patrolUnits={patrolUnits} user={currentUser}/></ProtectedRoute>} />
        <Route path="/patrol/navigation" element={<ProtectedRoute allowedRole="patrol"><NavigationScreen /></ProtectedRoute>} />
        <Route path="/patrol/communication" element={<ProtectedRoute allowedRole="patrol"><Communication incidents={incidents} user={currentUser} role={role}/></ProtectedRoute>} />
        <Route path="/patrol/stats" element={<ProtectedRoute allowedRole="patrol"><MyStats incidents={incidents} user={currentUser} /></ProtectedRoute>} />

        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard
                incidents={incidents}
                updateStatus={updateStatus}
                role={role}
                user={currentUser}
                assignPatrol={assignPatrol}
                patrolUnits={patrolUnits}
              />
            </ProtectedRoute>
          }
        />

        <Route
          path="/emergency"
          element={
            <ProtectedRoute allowedRole="admin">
              <Emergency incidents={incidents} />
            </ProtectedRoute>
          }
        />

        </Routes>
      </main>
          </div>
    </BrowserRouter>
  );
}

export default App;
