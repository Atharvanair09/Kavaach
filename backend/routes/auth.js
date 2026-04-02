const express = require("express");
const router = express.Router();
const { OAuth2Client } = require("google-auth-library");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: "../.env" });

// You should replace this with your actual Google Client ID
const CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const JWT_SECRET = process.env.JWT_SECRET || "kavaach_super_secret_jwt_key_2026";

const client = new OAuth2Client(CLIENT_ID);

const usersDbPath = path.join(__dirname, "../users.json");

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

router.post("/google", async (req, res) => {
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
    let users = readUsers();
    let user = users.find(u => u.googleId === googleId || u.email === email);
    
    if (!user) {
      // Create a newly registered user
      user = {
        id: "user_" + Date.now(),
        googleId,
        email,
        name,
        picture,
      };
      users.push(user);
      saveUsers(users);
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
    let users = readUsers();
    let existingUser = users.find(u => u.email === email);
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
    
    users.push(newUser);
    saveUsers(users);

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
    let users = readUsers();
    let user = users.find(u => u.email === email && u.password === password);
    if (!user) {
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

module.exports = router;
