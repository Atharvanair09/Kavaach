import { initializeApp } from "firebase/app";
import { getFirestore, collection, addDoc, serverTimestamp } from "firebase/firestore";

const firebaseConfig = {
    apiKey: "AIzaSyDR-pRkCHe3MiRK0cUh5iH7qgpnlOwbeO0",
    authDomain: "safetext-cf7ab.firebaseapp.com",
    projectId: "safetext-cf7ab",
    storageBucket: "safetext-cf7ab.firebasestorage.app",
    messagingSenderId: "55788182047",
    appId: "1:55788182047:web:c91d8bf9b1d4c16828532a",
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