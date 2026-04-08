const express = require("express");
const router = express.Router();
const axios = require("axios");

const userSessions = {};

const responseBank = {

  positive: [
    "That's great to hear! Keep smiling",
    "Glad you're feeling good!",
    "Nice! Positive vibes matter.",
    "Happy to hear that. Take care!",
    "That's great to hear! I'm glad you're feeling happy.",
    "It's wonderful that you're feeling good today.",
    "I'm happy to hear that. Keep taking care of yourself.",
    "That’s really nice to hear! Positive moments matter."
  ],

  stalking: [
    "If someone is following you, move to a crowded place immediately.",
    "Stay in well-lit areas and avoid isolation.",
    "Enter a shop or public place if possible.",
    "Call someone you trust and share your location.",
    "Stay alert and avoid confrontation.",
    "If someone is following you, try moving to a crowded and well-lit place.",
    "Stay close to other people and avoid isolated areas.",
    "You may want to call someone you trust and tell them where you are.",
    "Consider sharing your live location with someone you trust.",
    "If the situation continues, contacting local authorities may help."
  ],

  abuse: [
    "I'm really sorry you're facing this. Your safety matters.",
    "Try to move to a safe place immediately.",
    "Reach out to someone you trust.",
    "You deserve to feel safe.",
    "Consider contacting authorities if needed.",
    "I'm really sorry you're experiencing this. Your safety matters.",
    "Try to move somewhere safe if possible.",
    "Consider reaching out to someone you trust for support.",
    "You deserve to feel safe and protected.",
    "Talking to a trusted person or support helpline might help."
  ],

  danger: [
    "You might be in danger. Are you safe right now?",
    "Please move to a safe place immediately.",
    "Contact emergency services if possible.",
    "Alert someone you trust right now.",
    "Try to move to a safe public place immediately.",
    "If you feel unsafe, contacting emergency services may help.",
    "Consider alerting someone you trust about your situation."
  ],

  mental_health: [
    "I'm really sorry you're feeling this way.",
    "You're not alone. I'm here to listen.",
    "Talking to someone you trust might help.",
    "Your feelings are valid.",
    "Would you like to share more?",
    "You're not alone. Many people go through difficult moments.",
    "Talking to someone you trust might help you feel supported.",
    "It may help to speak with a counselor or mental health professional.",
    "Your feelings are valid. Would you like to talk more about it?"
  ],

  womens_health: [
    "If you're experiencing unusual symptoms, consulting a healthcare professional may help.",
    "Rest and proper hydration can help with many health issues.",
    "If symptoms continue, seeking medical advice is recommended.",
    "Taking care of your health is important.",
    "It seems like you're not feeling well. Please take rest and stay hydrated.",
    "Fever can be managed with rest and fluids.",
    "Monitor your symptoms and take care.",
    "If symptoms persist, consult a doctor.",
    "Stay hydrated and get enough rest."
  ],

  period: [
    "Menstrual cramps are common. Rest and a heating pad may help.",
    "Stay hydrated and take light rest.",
    "Warm drinks can help reduce discomfort.",
    "If pain is severe, consider consulting a doctor.",
    "Light exercise and staying hydrated may help reduce cramps.",
    "If your pain becomes severe, consider consulting a doctor.",
    "Warm drinks or rest might help with menstrual discomfort."
  ],

  pregnancy: [
    "Proper nutrition and rest are important during pregnancy.",
    "Consider consulting a doctor for guidance.",
    "Take care of your health and avoid stress.",
    "If you feel discomfort, seek medical advice.",
    "If you suspect pregnancy, a pregnancy test can help confirm it.",
    "If you experience severe pain or bleeding, please seek medical care immediately.",
    "Consulting a doctor can help answer pregnancy-related concerns."
  ],

  general: [
    "I'm here to listen. Tell me more.",
    "Would you like to share more details?",
    "I'm here to help.",
    "Tell me what's going on.",
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

  if (/(happy|great|good|excited|fine|awesome)/.test(text)) return "positive";
  
  if (/(stalk|follow|someone behind|watching)/.test(text)) return "stalking";
  
  if (/(abuse|violence|hit|beat|hurt)/.test(text)) return "abuse";
  
  if (/(danger|unsafe|scared|help)/.test(text)) return "danger";
  
  if (/(sad|depress|anxiety|lonely|stress)/.test(text)) return "mental_health";
  
  if (/(period|menstrual|cramp|bleeding)/.test(text)) return "period";
  
  if (/(pregnant|pregnancy|missed period)/.test(text)) return "pregnancy";
  
  if (/(fever|cold|cough|pain|infection|headache|vomit|weak)/.test(text)) return "womens_health";

  return "general";
}

function getSmartReply(category, risk, lastRisk, userId) {
  if (category === "positive") {
    return getRandomResponse("positive");
  }

  if (category === "womens_health" || category === "period" || category === "pregnancy") {
    return getRandomResponse(category);
  }

  let reply = getRandomResponse(category);

  if (risk === "high") {
    if (lastRisk === "high") {
      return reply + " This situation seems urgent. Please contact emergency services immediately.";
    }
  }

  if (risk === "medium") {
    const responses = [
      "Please stay alert and aware of your surroundings.",
      "Consider sharing your location with someone you trust.",
      "Stay cautious and keep your phone accessible."
    ];
    reply += " " + responses[Math.floor(Math.random() * responses.length)];
  }

  if (category === "stalking" && userSessions[userId] && userSessions[userId].lastCategory === "stalking") {
    reply += " If the person continues following you, consider contacting authorities.";
  }

  return reply;
}

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

  if (!userSessions[userId]) {
    userSessions[userId] = {
      lastRisk: null,
      lastCategory: null,
      history: []
    };
  }

  userSessions[userId].history.push({ user: message });

  let risk = "low";

  try {
    const response = await axios.post("http://127.0.0.1:8000/predict", {
      text: message
    });

    risk = response.data.risk;
    const emotion = response.data.emotion;

    if (emotion === "happy" || emotion === "positive") {
      risk = "low";
    }

  } catch (error) {
    console.log("ML API error:", error.message);
  }

  const category = detectCategory(message);

  if (["womens_health", "period", "pregnancy", "positive"].includes(category)) {
    risk = "low";
  }

  if (category === "stalking" || category === "abuse" || category === "danger") {
    risk = "high";
  }

  const reply = getSmartReply(category, risk, userSessions[userId].lastRisk, userId);

  let action = "none";
  let ui = "green";

  if (risk === "high") {
    ui = "red";
    if (userSessions[userId].lastRisk === "high") {
      action = "trigger_sos";
    }
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

module.exports = router;