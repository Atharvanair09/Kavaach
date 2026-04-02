const express = require("express");
const router = express.Router();
const { spawn } = require("child_process");

const userSessions = {};

const responseBank = {

  positive: [
    "That's great to hear! I'm glad you're feeling happy.",
    "It's wonderful that you're feeling good today.",
    "I'm happy to hear that. Keep taking care of yourself.",
    "That’s really nice to hear! Positive moments matter."
  ],

  stalking: [
    "If someone is following you, try moving to a crowded and well-lit place.",
    "Stay close to other people and avoid isolated areas.",
    "If possible, enter a shop or public place.",
    "You may want to call someone you trust and tell them where you are.",
    "Consider sharing your live location with someone you trust.",
    "If the situation continues, contacting local authorities may help."
  ],

  abuse: [
    "I'm really sorry you're experiencing this. Your safety matters.",
    "Try to move somewhere safe if possible.",
    "Consider reaching out to someone you trust for support.",
    "You deserve to feel safe and protected.",
    "Talking to a trusted person or support helpline might help."
  ],

  mental_health: [
    "I'm really sorry you're feeling this way.",
    "You're not alone. Many people go through difficult moments.",
    "Talking to someone you trust might help you feel supported.",
    "It may help to speak with a counselor or mental health professional.",
    "Your feelings are valid. Would you like to talk more about it?"
  ],

  womens_health: [
    "If you're experiencing unusual symptoms, consulting a healthcare professional may help.",
    "Rest and proper hydration can help with many health issues.",
    "If symptoms continue, seeking medical advice is recommended.",
    "Taking care of your health is important."
  ],

  period: [
    "Menstrual cramps are common. Rest and a heating pad may help.",
    "Light exercise and staying hydrated may help reduce cramps.",
    "If your pain becomes severe, consider consulting a doctor.",
    "Warm drinks or rest might help with menstrual discomfort."
  ],

  pregnancy: [
    "If you suspect pregnancy, a pregnancy test can help confirm it.",
    "Proper nutrition and rest are important during pregnancy.",
    "If you experience severe pain or bleeding, please seek medical care immediately.",
    "Consulting a doctor can help answer pregnancy-related concerns."
  ],

  danger: [
    "You might be in danger. Are you safe right now?",
    "Try to move to a safe public place immediately.",
    "If you feel unsafe, contacting emergency services may help.",
    "Consider alerting someone you trust about your situation."
  ],

  general: [
    "I'm here to listen. Tell me more about what's happening.",
    "That sounds difficult. Would you like to share more?",
    "I'm here to help. How are you feeling right now?",
    "Feel free to tell me what's going on."
  ]
};

function getRandomResponse(category) {
  const responses = responseBank[category] || responseBank.general;
  return responses[Math.floor(Math.random() * responses.length)];
}

function detectCategory(message) {

  const text = message.toLowerCase();

  if (/(happy|great|good|excited|fine)/.test(text))
    return "positive";

  if (/(stalk|follow|someone behind|watching me)/.test(text))
    return "stalking";

  if (/(abuse|violence|hit|beat|hurt me)/.test(text))
    return "abuse";

  if (/(period|menstrual|cramp|bleeding)/.test(text))
    return "period";

  if (/(pregnant|pregnancy|missed period)/.test(text))
    return "pregnancy";

  if (/(depress|sad|anxiety|lonely|stress)/.test(text))
    return "mental_health";

  if (/(health|pain|infection|fever)/.test(text))
    return "womens_health";

  return "general";
}

router.post("/", async (req, res) => {

  const userId = req.body.userId || "default";
  const message = req.body.message || "";

  if (!userSessions[userId]) {
    userSessions[userId] = {
      lastRisk: null,
      lastCategory: null,
      history: []
    };
  }

  userSessions[userId].history.push({ user: message });

  try {

    // const py = spawn("python", ["bert_model.py"]);
    const response = await fetch("http://localhost:5500/predict", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ message })
    });

    let dataString = "";

    py.stdout.on("data", (data) => {
      dataString += data.toString();
    });

    py.stderr.on("data", (err) => {
      console.error("Python Error:", err.toString());
    });

    py.stdin.write(message);
    py.stdin.end();

    py.on("close", () => {

      let mlData = { risk: "low", emotion: "neutral" };

      try {
        mlData = JSON.parse(dataString);
      } catch {
        console.log("Model parse failed, using fallback.");
      }

      let risk = mlData.risk;
      let emotion = mlData.emotion;

      if (emotion === "happy" || emotion === "positive") {
        risk = "low";
      }

      const category = detectCategory(message);

      if (category === "stalking" || category === "abuse") {
        risk = "high";
      }

      let reply = getRandomResponse(category);

      if (category === "stalking" && userSessions[userId].lastCategory === "stalking") {
        reply += " If the person continues following you, consider contacting authorities.";
      }

      let action = "none";
      let ui = "green";

      if (risk === "high") {

        if (userSessions[userId].lastRisk === "high") {
          reply += " This situation seems urgent. Please contact emergency services.";
          action = "trigger_sos";
        }

        ui = "red";

      } else if (risk === "medium") {

        ui = "yellow";
        action = "share_location";

      }

      userSessions[userId].lastRisk = risk;
      userSessions[userId].lastCategory = category;

      userSessions[userId].history.push({ bot: reply });

      res.json({
        reply,
        action,
        ui
      });

    });

  } catch (error) {

    console.error(error);

    res.status(500).json({
      reply: "I'm having trouble responding right now. Please try again.",
      action: "none",
      ui: "green"
    });

  }

});

module.exports = router;