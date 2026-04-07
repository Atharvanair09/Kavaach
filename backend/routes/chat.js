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
  const safePlaces = req.body.safePlaces || "";

  if (!userSessions[userId]) {
    userSessions[userId] = {
      lastRisk: null,
      lastCategory: null,
      history: []
    };
  }

  userSessions[userId].history.push({ user: message });

  try {

    let mlData = { risk: "low", emotion: "neutral" };
    try {
      const response = await fetch("http://localhost:5500/predict", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ message })
      });
      if (response.ok) {
        mlData = await response.json();
      } else {
        console.log("Model HTTP Error", response.status);
      }
    } catch (err) {
      console.log("Model fetch failed, using fallback.", err.message);
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

    // --- NEW: Dynamic System Prompt based on Risk Level ---
    let systemPrompt = `You are Jarvis, a highly protective personal safety assistant. Keep responses short (1-3 sentences). IMPORTANT: To protect the user from aggressive onlookers, NEVER mention words like "SOS", "Police", "track", or "danger". Act completely casually and covertly. `;
    
    if (risk === "low") {
      systemPrompt += "Be a friendly listener. Completely hear them out to understand their feelings.";
    } else if (risk === "medium") {
      systemPrompt += "Casually prompt them to mention their current location or surroundings without sounding alarmed. Keep the tone completely relaxed and normal.";
      if (safePlaces) {
        systemPrompt += ` You subtly suggest they move to one of these safe locations if they feel uneasy: ${safePlaces}.`;
      }
    } else if (risk === "high") {
      systemPrompt += "Provide extremely calm, subtle comfort. Keep the tone very casual so a hostile onlooker wouldn't know this is a safety app. Stay with them.";
      if (safePlaces) {
        systemPrompt += ` Subtly suggest that they move to one of these nearby safe locations, but do not use words like 'Police' explicitly (e.g. say 'the station near [address]'): ${safePlaces}.`;
      }
    }

    // --- Generative AI Conversation Logic ---
    let reply = "I'm having trouble connecting to my conversation module, but my safety routines are still tracking you.";
    try {
      const openRouterRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
          "HTTP-Referer": "http://localhost:5000",
          "X-Title": "Kavaach Safety App",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: "meta-llama/llama-3-8b-instruct:free", // Safely using a 100% Free model to prevent zero-credit rejection errors
          messages: [
            { role: "system", content: systemPrompt },
            ...userSessions[userId].history.map(msg => ({
              role: msg.user ? "user" : "assistant",
              content: msg.user || msg.bot
            }))
          ]
        })
      });

      if (openRouterRes.ok) {
        const data = await openRouterRes.json();
        reply = data.choices[0].message.content;
      } else {
        console.error("OpenRouter API Failed...", await openRouterRes.text());
        reply = getRandomResponse(category); 
      }
    } catch (err) {
      console.error("OpenRouter fetch failed:", err);
      reply = getRandomResponse(category); 
    }

    // --- Action Calculation & Backend Alerting ---
    let action = "none";
    let ui = "green";

    if (risk === "high") {
      ui = "red";
      action = "trigger_sos";
      
      // Backend SOS Integration (Twilio/Firebase structure goes here)
      console.log(`[URGENT SOS] Dispatching coordinates and alerts for User: ${userId} to Emergency Contacts and Local Authorities!`);
      
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