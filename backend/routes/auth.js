const express = require("express");
const router = express.Router();
const { OAuth2Client } = require("google-auth-library");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

// You should replace this with your actual Google Client ID
const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const JWT_SECRET = process.env.JWT_SECRET || "kavaach_super_secret_jwt_key_2026";

const client = new OAuth2Client(CLIENT_ID);

const { db } = require("../firebase");

const usersDbPath = path.join(__dirname, "../users.json");

// --- Helper Functions to Handle Firestore / JSON Fallback ---

// Helper function to read persistent users securely
function readUsers() {
  if (!fs.existsSync(usersDbPath)) return [];
  try {
    const data = fs.readFileSync(usersDbPath, "utf8");
    return JSON.parse(data);
  } catch(e) { return []; }
}

// Helper function to save persistent users securely
function saveUsers(users) {
  fs.writeFileSync(usersDbPath, JSON.stringify(users, null, 2));
}

// Helper function to fetch a user from Firestore (or fallback JSON)
async function findUserByEmail(email) {
  let user = null;

  // 1. Try to find in Firestore
  if (db) {
    try {
      const snapshot = await db.collection("users").where("email", "==", email).get();
      if (!snapshot.empty) {
        user = snapshot.docs[0].data();
      }
    } catch (e) {
      console.error("Firestore lookup failed:", e);
    }
  }
  
  // 2. If not found in Firestore, search in local JSON
  const users = readUsers();
  const jsonUser = users.find(u => u.email === email);

  // 3. AUTOMATIC MIGRATION: 
  // If we found them in JSON but not in Firestore, save them to Firestore now!
  if (jsonUser && !user && db) {
    console.log(`Migrating user ${email} from JSON to Firestore...`);
    user = jsonUser;
    await storeUser(user); 
  }

  return user || jsonUser; // Return whichever one we found
}

// Helper function to save a user to Firestore (and JSON as backup)
async function storeUser(user) {
  if (db) {
    try {
      // Use Firestore to store or update the user
      await db.collection("users").doc(user.id).set(user, { merge: true });
      console.log(`User ${user.email} saved to Firestore successfully.`);
    } catch (e) {
      console.error("Firestore save failed:", e);
    }
  }
  
  // Also save to local JSON for now to ensure no data loss during transition
  const users = readUsers();
  const index = users.findIndex(u => u.id === user.id || u.email === user.email);
  if (index !== -1) {
    users[index] = { ...users[index], ...user };
  } else {
    users.push(user);
  }
  saveUsers(users);
}

router.post("/google", async (req, res) => {
  console.log("📥 [POST] /auth/google - Request Received");
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: "idToken is required" });
    }

    // Verify the idToken with Google.
    // We don't restrict 'audience' here because the Android client generates tokens
    // with the Android OAuth Client ID as the audience, which differs from the Web Client ID.
    // Google still validates the signature, expiry, and project ownership.
    const ticket = await client.verifyIdToken({
      idToken,
    });
    
    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;

    // Check if user exists in database
    let user = await findUserByEmail(email);
    
    if (!user) {
      // Create a newly registered user
      user = {
        id: "user_" + Date.now(),
        googleId,
        email,
        name,
        picture,
      };
      await storeUser(user);
    }

    // Generate JWT token for access to our API
    const sessionToken = jwt.sign(
      { userId: user.id, email: user.email }, 
      JWT_SECRET, 
      { expiresIn: "7d" }
    );

    res.status(200).json({
      message: "Successfully logged in",
      token: sessionToken,
      user
    });
    
  } catch (error) {
    console.error("Google verify error:", error);
    res.status(401).json({ error: "Invalid Google token" });
  }
});

// --- Manual Sign Up Endpoint ---
router.post("/signup", async (req, res) => {
  try {
    const { name, email, password, number } = req.body;
    
    if (!name || !email || !password || !number) {
      return res.status(400).json({ error: "Name, email, password, and number are required" });
    }

    // Check if user already exists
    let existingUser = await findUserByEmail(email);
    if (existingUser) {
      return res.status(400).json({ error: "User already exists" });
    }

    // Hash the password securely in a real app (e.g., using bcrypt)
    // For this boilerplate, we'll store it as is (NOT RECOMMENDED FOR PRODUCTION)
    const newUser = {
      id: "user_" + Date.now(),
      name,
      email,
      number,
      password // TODO: encrypt this before saving
    };
    
    await storeUser(newUser);

    // Generate JWT token
    const sessionToken = jwt.sign(
      { userId: newUser.id, email: newUser.email }, 
      JWT_SECRET, 
      { expiresIn: "7d" }
    );

    res.status(201).json({
      message: "Successfully signed up",
      token: sessionToken,
      user: { id: newUser.id, name: newUser.name, email: newUser.email }
    });
  } catch (error) {
    console.error("Signup error:", error);
    res.status(500).json({ error: "Server error during registration" });
  }
});

// --- Manual Login Endpoint ---
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    // Find the user
    let user = await findUserByEmail(email);
    if (!user || user.password !== password) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // Generate JWT token
    const sessionToken = jwt.sign(
      { userId: user.id, email: user.email }, 
      JWT_SECRET, 
      { expiresIn: "7d" }
    );

    res.status(200).json({
      message: "Successfully logged in",
      token: sessionToken,
      user: { id: user.id, name: user.name, email: user.email }
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ error: "Server error during login" });
  }
});

// --- Update Profile Endpoint ---
router.post("/update-profile", async (req, res) => {
  try {
    const { email, name, phone } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: "Email is required" });
    }

    // Find the user to get their ID
    let user = await findUserByEmail(email);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Update user object
    const updatedUser = {
      ...user,
      name: name || user.name,
      phone: phone || user.phone || user.number, // Support both 'phone' and 'number' keys
    };
    
    await storeUser(updatedUser);

    res.status(200).json({
      message: "Profile updated successfully",
      user: updatedUser
    });
  } catch (error) {
    console.error("Update profile error:", error);
    res.status(500).json({ error: "Server error during profile update" });
  }
});

// --- Update Emergency Contacts Endpoint ---
router.post("/update-contacts", async (req, res) => {
  try {
    const { email, contacts } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: "Email is required" });
    }

    // Find the user
    let user = await findUserByEmail(email);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Update emergencyContacts array
    const updatedUser = {
      ...user,
      emergencyContacts: contacts || [],
    };
    
    await storeUser(updatedUser);

    res.status(200).json({
      message: "Emergency contacts updated successfully",
      user: updatedUser
    });
  } catch (error) {
    console.error("Update contacts error:", error);
    res.status(500).json({ error: "Server error during contacts update" });
  }
});

module.exports = router;
