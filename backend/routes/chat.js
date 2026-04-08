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

  if (/(abuse|violence|hit|beat|hurt|beats me|hurts me|hitting me|slapped me|punched me|kicked me|my husband|my boyfriend|my partner|my father|my brother|domestic|choke|threaten|forced me|assault)/.test(text))
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
    // Abuse/violence = HIGH risk (silent SOS)
    // Stalking = MEDIUM risk (guide to safe location, share GPS)
    if (category === "abuse") {
      risk = "high";
    } else if (category === "stalking") {
      risk = "medium";
    }

    // --- Dynamic System Prompt based on Risk Level ---
    let systemPrompt = `You are Jarvis, a warm and caring personal assistant having a private chat. Keep responses to 1-2 sentences maximum. CRITICAL RULES: Never mention "SOS", "police", "emergency", "danger", "track", "alert", or anything that sounds like a safety app — someone hostile may be watching the screen. Sound completely natural and human. `;
    
    if (risk === "low") {
      systemPrompt += "Be a friendly, casual listener. Hear them out and respond warmly.";
    } else if (risk === "medium") {
      if (category === "stalking") {
        // STALKING: Casually redirect to a named safe place — keep tone breezy so a follower won't notice
        if (safePlaces) {
          systemPrompt += `The user feels they are being followed or watched. You MUST naturally work in a suggestion to head to one of these specific nearby places by name in your reply: ${safePlaces}. Frame it as a casual idea, like "Oh hey, why don't you pop into [Place Name] for a bit?" or "There's a [Place Name] nearby, maybe grab a coffee there?". Keep it light and friendly. Do NOT say anything alarming.`;
        } else {
          systemPrompt += "The user feels they are being followed. Casually suggest they move towards a busy, well-lit public place — a shop, cafe, or busy street — without sounding alarmed.";
        }
      } else {
        systemPrompt += "Sound caring and relaxed. Gently ask where they are or how their surroundings feel, as if catching up with a friend.";
        if (safePlaces) {
          systemPrompt += ` If they seem uneasy, casually mention they could hang out near one of these spots: ${safePlaces}.`;
        }
      }
    } else if (risk === "high") {
      // HIGH RISK: Empathetic probe to keep user talking — SOS fires silently on the client side.
      systemPrompt += `The user has just described something that sounds very distressing (e.g. domestic abuse, physical violence, or a serious threat). Your job is to respond with genuine warmth and an open-ended question that encourages them to share more — like a caring friend would. Example tone: "Oh no, I'm so sorry to hear that. Tell me more — what happened?" or "That sounds really hard. Are you okay right now?". Do NOT suggest solutions, do NOT mention authorities. Just make them feel heard and keep them talking.`;
      if (safePlaces) {
        systemPrompt += ` If it feels natural, you may very casually mention they could step out to somewhere like: ${safePlaces}.`;
      }
    }

    // --- Generative AI Conversation Logic ---
    let reply = "I'm having trouble connecting to my conversation module, but my safety routines are still tracking you.";
    
    const modelsToTry = [
      "mistralai/mistral-7b-instruct:free",
      "meta-llama/llama-3.1-8b-instruct:free"
    ];

    // Build chat history for AI — trim to last 10 messages to stay within
    // free-tier model context limits (avoids falling back to canned responses)
    const MAX_HISTORY = 10;
    const MAX_CONTENT_LEN = 300;
    const trimmedHistory = userSessions[userId].history.slice(-MAX_HISTORY);

    const chatMessages = [
      { role: "system", content: systemPrompt },
      ...trimmedHistory
        .filter(msg => msg.user || msg.bot)   // skip any malformed entries
        .map(msg => ({
          role: msg.user ? "user" : "assistant",
          content: (msg.user || msg.bot).substring(0, MAX_CONTENT_LEN)
        }))
    ];

    console.log(`[JARVIS] Sending ${chatMessages.length - 1} history msgs to model (trimmed to last ${MAX_HISTORY}).`);

    let aiSuccess = false;
    for (const modelId of modelsToTry) {
      if (aiSuccess) break;
      try {
        console.log(`[JARVIS] Trying model: ${modelId} | Risk: ${risk} | Category: ${category} | Message: "${message}"`);
        const openRouterRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
            "HTTP-Referer": "http://localhost:5000",
            "X-Title": "Kavaach Safety App",
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ model: modelId, messages: chatMessages })
        });

        if (openRouterRes.ok) {
          const data = await openRouterRes.json();
          reply = data.choices[0].message.content;
          console.log(`[JARVIS] ✅ AI Reply (${modelId}): "${reply.substring(0, 80)}..."`);
          aiSuccess = true;
        } else {
          const errText = await openRouterRes.text();
          console.warn(`[JARVIS] ⚠️ Model ${modelId} failed (${openRouterRes.status}), trying next...`);
        }
      } catch (err) {
        console.warn(`[JARVIS] ⚠️ Model ${modelId} fetch error: ${err.message}, trying next...`);
      }
    }

    if (!aiSuccess) {
      // For stalking, inject the actual safe place name into the fallback if we have it
      if (category === "stalking" && safePlaces) {
        reply = `Oh, actually — there's ${safePlaces.split(",")[0].trim()} nearby, why don't you head over there for a bit? Might be a nice change of scenery.`;
      } else {
        reply = getRandomResponse(category);
      }
      console.log(`[JARVIS] ❌ All models failed. Using fallback from category: ${category}`);
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