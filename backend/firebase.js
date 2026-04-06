const admin = require("firebase-admin");
const path = require("path");

// You'll need to download your service account key from the Firebase Console:
// Project Settings -> Service Accounts -> Generate new private key.
// Save it as 'serviceAccountKey.json' in this folder.
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("✅ Firebase Admin SDK: CONNECTED");
} catch (error) {
  console.warn("⚠️ Firebase serviceAccountKey.json not found or invalid. Firestore won't work until this is fixed.");
  console.warn("Follow the instructions in 'firebase_migration.md' to set it up.");
}

const db = admin.apps.length ? admin.firestore() : null;

if (db) {
  // Connection test
  db.listCollections().then(() => {
    console.log("🔥 Firestore: Connection verified, ready to store users!");
  }).catch(e => {
    console.error("❌ Firestore connection failed (check your credentials):", e.message);
  });
}

module.exports = { admin, db };

