import { initializeApp } from "firebase/app";
import { getFirestore, collection, addDoc, serverTimestamp } from "firebase/firestore";

const firebaseConfig = {
    apiKey: "AIzaSyBDvJ-EVsgZBmW4QGXOLnp-E88tUuYyeqE",
    authDomain: "kavaach-ee691.firebaseapp.com",
    projectId: "kavaach-ee691",
    storageBucket: "kavaach-ee691.firebasestorage.app",
    messagingSenderId: "851304119288",
    appId: "1:851304119288:web:7f6f7d4c8853c43202e", // Aligned with Kavaach Project
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);

/**
 * Creates a real-time notification in Firestore
 * @param {string} type - 'alert', 'success', or 'info'
 * @param {string} text - The notification message
 */
export const createNotification = async (type, text) => {
  try {
    await addDoc(collection(db, "notifications"), {
      type,
      text,
      timestamp: serverTimestamp(),
      read: false
    });
  } catch (error) {
    console.error("Error creating notification:", error);
  }
};