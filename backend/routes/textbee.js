const express = require("express");
const router = express.Router();
const sendSMS = require("../utils/sendSMS");
const { processChatMessage } = require("../utils/chatEngine");

// GET route for browser verification
router.get("/", (req, res) => {
  res.send("<h1>✅ TextBee Webhook is LIVE!</h1><p>Your ngrok tunnel and Node server are connected correctly. Now, send an SMS to this device to trigger the chatbot logic.</p>");
});

/**
 * Webhook for TextBee.dev incoming messages.
 * Matches your actual payload:
 * {
 *   "message": "Help me Jarvis ",
 *   "sender": "+919859850222",
 *   "webhookEvent": "MESSAGE_RECEIVED"
 * }
 */
router.post("/", async (req, res) => {
  console.log("🔔 TextBee Webhook triggered with body:", JSON.stringify(req.body, null, 2));

  const { webhookEvent, sender, message } = req.body;

  // Verify this is a message received event
  if (webhookEvent !== "MESSAGE_RECEIVED") {
    return res.status(200).send("Event ignored.");
  }

  if (!sender || !message) {
    console.log("⚠️ Missing sender or message in payload.");
    return res.status(400).send("Invalid payload.");
  }

  console.log(`📩 Received offline message from ${sender}: ${message}`);

  try {
    // 1. Process message through our ML/Chat Logic
    // We use the sender's phone number as the userId to maintain their session history
    const result = await processChatMessage(sender, message, true);
    
    const botReply = result.reply;
    console.log(`🧠 ML Analysis complete. Risk: ${result.risk}. Category: ${result.category || 'N/A'}`);

    // 2. Send the response back to the user via TextBee SMS
    await sendSMS(sender, botReply);

    console.log(`📤 Sent offline response to ${sender}: ${botReply}`);
    res.status(200).send("OK");
  } catch (error) {
    console.error("❌ Error in TextBee offline chatbot:", error.message);
    res.status(500).send("Internal Server Error");
  }
});

module.exports = router;
