const express = require("express");
const router = express.Router();
const { processChatMessage } = require("../utils/chatEngine");
const { db, admin } = require("../firebase");

router.post("/", async (req, res) => {
  const userId = req.body.userId || "default";
  const message = req.body.message || "";
  const sessionId = req.body.sessionId || "unknown_session";

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
          sessionId: sessionId,
          message: message,
          reply: result.reply,
          category: result.category || "general",
          risk: result.risk || "low",
          ui: result.ui || "green",
          action: result.action || "none",
          time: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Chat updated for session: ${sessionId}`);
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

    const allMessages = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      allMessages.push({
        id: doc.id,
        ...data,
        time: data.time ? data.time.toDate() : new Date()
      });
    });

    // Group into sessions
    const sessionsMap = {};
    allMessages.forEach(msg => {
      const sid = msg.sessionId || "legacy_session";
      if (!sessionsMap[sid]) {
        sessionsMap[sid] = {
          sessionId: sid,
          time: msg.time,
          messages: []
        };
      }
      sessionsMap[sid].messages.push(msg);
      // Keep the session time as the time of the latest message in that session
      if (msg.time > sessionsMap[sid].time) {
          sessionsMap[sid].time = msg.time;
      }
    });

    const sessionHistory = Object.values(sessionsMap).sort((a, b) => b.time - a.time);

    res.json(sessionHistory);
  } catch (error) {
    console.error("Error fetching chat history:", error);
    res.status(500).json({ error: "Internal server error during history fetch" });
  }
});

module.exports = router;