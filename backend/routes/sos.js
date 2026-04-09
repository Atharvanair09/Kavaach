const express = require("express");
const router = express.Router();
const { db } = require("../firebase");
const sendSMS = require("../utils/sendSMS");

/**
 * POST /sos
 * Body: { userId: string, location: { lat: number, lng: number } }
 *
 * Fetches emergency contacts from Firestore and sends SMS to each.
 */
router.post("/", async (req, res) => {
  const { userId, location, lat: topLat, lng: topLng, message } = req.body;

  // Support both { location: {lat, lng} } and legacy { lat, lng }
  const lat = location?.lat ?? topLat;
  const lng = location?.lng ?? topLng;

  console.log("🚨 SOS REQUEST RECEIVED");
  console.log("User ID:", userId);
  console.log("Location:", { lat, lng });

  // ── 0. Log SOS to Firestore Alerts Collection ──────────────────────────────
  if (db) {
    try {
      await db.collection("sos_alerts").add({
        senderEmail: userId || "unknown@user.com",
        senderName: "Kavaach User", 
        location: { lat, lng },
        message: message || "Emergency! I need help.",
        timestamp: new Date(),
        status: "active",
      });
      console.log("✅ SOS persistent log created in Firestore collection 'sos_alerts'.");
    } catch (err) {
      console.error("❌ Firestore SOS logging failed:", err.message);
    }
  }

  if (!lat || !lng) {
    return res.status(400).json({ success: false, error: "Location (lat/lng) is required" });
  }

  const mapsLink = `https://maps.google.com/?q=${lat},${lng}`;
  const sosMessage = `🚨 SOS ALERT! ${message || "User needs help."} Location: ${mapsLink}`;

  // ── Fetch emergency contacts (priority: body > Firestore > fallback) ─────
  let contacts = req.body.contacts || [];

  if (contacts.length > 0) {
    console.log(`📋 Using ${contacts.length} contact(s) provided in request body.`);
  } else if (userId && db) {
    try {
      const userDoc = await db.collection("users").doc(userId).get();
      if (userDoc.exists) {
        const data = userDoc.data();
        contacts = data.emergencyContacts || [];
        console.log(`📋 Found ${contacts.length} emergency contact(s) for user ${userId}`);
      } else {
        console.warn(`⚠️ No Firestore document found for userId: ${userId}`);
      }
    } catch (err) {
      console.error("❌ Firestore fetch error:", err.message);
    }
  }

  // ── Fallback: use env EMERGENCY_PHONE if no Firestore contacts ────────────
  if (contacts.length === 0) {
    const fallbackPhone = process.env.EMERGENCY_PHONE;
    if (fallbackPhone) {
      contacts = [{ name: "Emergency Contact", phone: fallbackPhone }];
      console.log("⚠️ No stored contacts found. Using fallback EMERGENCY_PHONE.");
    } else {
      console.warn("⚠️ No contacts and no EMERGENCY_PHONE fallback set.");
    }
  }

  if (contacts.length === 0) {
    return res.status(400).json({
      success: false,
      error: "No emergency contacts found. Please add contacts in the app.",
    });
  }

  // ── Send SMS to each contact ──────────────────────────────────────────────
  const results = [];
  for (const contact of contacts) {
    try {
      await sendSMS(contact.phone, sosMessage);
      results.push({ phone: contact.phone, name: contact.name, status: "sent" });
    } catch (err) {
      console.error(`❌ Failed to SMS ${contact.name} (${contact.phone}):`, err.message);
      results.push({ phone: contact.phone, name: contact.name, status: "failed", error: err.message });
    }
  }

  const allSent = results.every((r) => r.status === "sent");
  return res.json({
    success: allSent,
    message: allSent ? "SOS sent to all contacts" : "SOS partially sent",
    results,
  });
});

/**
 * POST /sos/contacts
 * Body: { userId: string, contact: { name: string, phone: string } }
 *
 * Adds or updates an emergency contact in Firestore.
 */
router.post("/contacts", async (req, res) => {
  const { userId, contact } = req.body;

  if (!userId || !contact?.name || !contact?.phone) {
    return res.status(400).json({ success: false, error: "userId, contact.name, and contact.phone are required." });
  }

  if (!contact.phone.startsWith("+")) {
    return res.status(400).json({ success: false, error: "Phone number must include country code (e.g., +91XXXXXXXXXX)" });
  }

  if (!db) {
    return res.status(500).json({ success: false, error: "Firestore not initialized." });
  }

  try {
    const userRef = db.collection("users").doc(userId);
    await userRef.set(
      { emergencyContacts: require("firebase-admin").firestore.FieldValue.arrayUnion(contact) },
      { merge: true }
    );

    console.log(`✅ Added emergency contact for ${userId}:`, contact);
    return res.json({ success: true, message: "Contact saved successfully" });
  } catch (err) {
    console.error("❌ Firestore write error:", err.message);
    return res.status(500).json({ success: false, error: "Failed to save contact." });
  }
});

/**
 * GET /sos/contacts/:userId
 *
 * Fetches emergency contacts list from Firestore.
 */
router.get("/contacts/:userId", async (req, res) => {
  const { userId } = req.params;

  if (!userId) {
    return res.status(400).json({ success: false, error: "userId is required." });
  }

  if (!db) {
    return res.status(500).json({ success: false, error: "Firestore not initialized." });
  }

  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      return res.json({ success: true, contacts: [] });
    }

    const data = userDoc.data();
    return res.json({ success: true, contacts: data.emergencyContacts || [] });
  } catch (err) {
    console.error("❌ Firestore read error:", err.message);
    return res.status(500).json({ success: false, error: "Failed to fetch contacts." });
  }
});

/**
 * DELETE /sos/contacts
 * Body: { userId: string, contact: { name: string, phone: string } }
 *
 * Removes a specific emergency contact from Firestore.
 */
router.delete("/contacts", async (req, res) => {
  const { userId, contact } = req.body;

  if (!userId || !contact?.phone) {
    return res.status(400).json({ success: false, error: "userId and contact.phone are required." });
  }

  if (!db) {
    return res.status(500).json({ success: false, error: "Firestore not initialized." });
  }

  try {
    const userRef = db.collection("users").doc(userId);
    await userRef.update({
      emergencyContacts: require("firebase-admin").firestore.FieldValue.arrayRemove(contact),
    });

    console.log(`✅ Removed emergency contact for ${userId}:`, contact);
    return res.json({ success: true, message: "Contact removed successfully" });
  } catch (err) {
    console.error("❌ Firestore delete error:", err.message);
    return res.status(500).json({ success: false, error: "Failed to remove contact." });
  }
});

module.exports = router;