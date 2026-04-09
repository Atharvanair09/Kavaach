const express = require("express");
const router = express.Router();
const { processChatMessage } = require("../utils/chatEngine");
const { db, admin } = require("../firebase");

router.post("/", async (req, res) => {
  const userId = req.body.userId || "default";
  const message = req.body.message || "";

  if (!message) {
    return res.status(400).json({
      reply: "Message is required",
      action: "none",
      ui: "green"
    });
  }

  try {
    const result = await processChatMessage(userId, message);

    // PERSISTENCE: Save both message and reply to Firestore using Admin SDK
    if (db) {
      try {
        await db.collection("chats").add({
          userId: userId,
          message: message,
          reply: result.reply,
          category: result.category || "general",
          risk: result.risk || "low",
          ui: result.ui || "green",
          action: result.action || "none",
          time: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Chat history updated for user: ${userId}`);
      } catch (dbError) {
        console.error("❌ Firestore Chat Save Error:", dbError.message);
      }
    }

    res.json(result);
  } catch (error) {
    console.error("Error processing chat message:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/history/:userId", async (req, res) => {
  const userId = req.params.userId;

  try {
    if (!db) {
      return res.status(500).json({ error: "Database not initialized" });
    }

    const snapshot = await db.collection("chats")
      .where("userId", "==", userId)
      .get();

    const history = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      history.push({
        id: doc.id,
        ...data,
        time: data.time ? data.time.toDate() : new Date()
      });
    });

    // Sort in memory to avoid needing a composite index
    history.sort((a, b) => b.time - a.time);

    res.json(history);
  } catch (error) {
    console.error("Error fetching chat history:", error);
    res.status(500).json({ error: "Internal server error during history fetch" });
  }
});

module.exports = router;