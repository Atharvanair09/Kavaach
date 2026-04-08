const express = require("express");
const router = express.Router();
const { processChatMessage } = require("../utils/chatEngine");

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
    res.json(result);
  } catch (error) {
    console.error("Error processing chat message:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;