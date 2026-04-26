const axios = require("axios");

const userSessions = {};

// Fallback responses in case OpenRouter API fails
const fallbackResponses = {
  stalking: "I understand. Please try to stay in crowded areas and keep someone you trust informed of your location.",
  danger: "Your safety is the priority. Please move to a safe place immediately if you can.",
  general: "I'm here to listen. Tell me more about what's happening."
};

async function translateToEnglish(text) {
  // If text is primarily ASCII, assume it's English/BERT-friendly
  if (/^[\x00-\x7F]*$/.test(text)) return text;

  try {
    const response = await axios.post("https://openrouter.ai/api/v1/chat/completions", {
      model: "openai/gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a translator for a safety app. Translate the text to English. Respond ONLY with the translation." },
        { role: "user", content: text }
      ]
    }, {
      headers: {
        "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
        "Content-Type": "application/json"
      }
    });
    return response.data.choices[0].message.content.trim();
  } catch (error) {
    console.error("Translation failed:", error.message);
    return text;
  }
}

function detectCategory(message) {
  const text = message.toLowerCase();
  if (/(happy|great|good|excited|fine|awesome)/.test(text)) return "positive";
  if (/(stalk|follow|someone behind|watching|police|station)/.test(text)) return "stalking";
  if (/(abuse|violence|hit|beat|hurt|assault)/.test(text)) return "abuse";
  if (/(harass|uncomfortable|cab|driver|touching|inappropriate|creep|taxi)/.test(text)) return "harassment";
  if (/(danger|unsafe|scared|help|shelter|hospital|location|address)/.test(text)) return "danger";
  if (/(sad|depress|anxiety|lonely|stress)/.test(text)) return "mental_health";
  if (/(period|menstrual|cramp|bleeding)/.test(text)) return "period";
  if (/(pregnant|pregnancy|missed period)/.test(text)) return "pregnancy";
  if (/(fever|cold|cough|pain|infection|headache|vomit|weak)/.test(text)) return "womens_health";
  return "general";
}

async function getGenerativeReply(userId, userMessage, category, risk, isOffline = false) {
  const session = userSessions[userId];
  const history = session.history.slice(-6); // Keep last 3 turns
  const msgCount = session.messageCount;

  let systemPrompt = `
    You are Jarvis, a personal safety assistant for women, integrated into the Kavaach app. You are OPERATING IN INDIA.

    CORE BEHAVIOR:
    - Maintain natural, calm conversation at all times.
    - Do not list manual steps if an automated feature is available.
    - If the user is being followed or feels unsafe (STALKING, HARASSMENT, DANGER), inform them that a tactical map and recording tools are appearing below your message.
    - Specifically for uncomfortable situations (like cab rides), point them to the "START DISCREET RECORDING" and "UPLOAD PHOTOS" buttons you are providing.
    - Always let the user continue talking, even in high-risk situations.
    - Keep responses concise (2-3 sentences max), human-like, and warm.
    - NEVER repeat the same response twice.
    - ALWAYS respond in the EXACT SAME LANGUAGE as the user's message.
    - Adapt tone based on user emotion: calm, supportive, reassuring.

    RISK HANDLING (based on risk level: ${risk} | category: ${category}):

    1. NORMAL (low/no risk):
       - Engage in regular, supportive, friendly conversation.
       - Do NOT suggest safety actions or mention SOS.

    2. MEDIUM RISK (uncertain discomfort, anxiety, unease):
       - Show genuine concern and gently probe for clarity.
       - Offer light, non-alarming suggestions only if relevant.
       - Do NOT trigger SOS or alerts yet.

    3. HIGH RISK (clear danger signals):

       A. ABUSE / HARASSMENT / STALKING:
          - Respond with empathy. Inform them that you are providing a discreet recording button and an upload option below.
          - Tell them to use the recording button immediately if they feel unsafe.
          - Mention helplines naturally: iCall (9152987821), Women's Helpline (181).
          - Reference nearby safe places shown on screen (shelters, police, hospitals).

       B. BEING FOLLOWED (category: stalking):
          - Stay calm and discreet in tone.
          - Advise sharing live location with a trusted contact.
          - Trigger an alert to dashboard with a "being followed" status (yellow).
          - Suggest stepping into a populated/visible public space.

       C. UNSAFE TRAVEL - Cab / Unknown Area (category: danger):
          - Stay engaged and conversational — do not alarm the user.
          - Ask naturally for key details: vehicle number, current location/landmark.
          - Suggest starting an audio recording discreetly for safety.
          - Recommend sharing trip details with their trusted circle.

       D. MENTAL HEALTH - Depression / Distress / Postpartum (category: mental_health):
          - Be empathetic, gentle, and non-clinical.
          - Avoid emergency actions unless risk clearly escalates.
          - Offer resources only if clearly needed (e.g., iCall: 9152987821).

    GOLDEN RULES:
    - NEVER panic the user.
    - NEVER force actions or give ultimatums.
    - Prioritize subtle guidance over direct commands.
    - End every response with a soft open question OR a clear next step.

    CURRENT CONTEXT:
    - User Message Count: ${msgCount}
    - Detected Category: ${category}
    - Risk Level: ${risk}
    - Mode: ${isOffline ? "OFFLINE (SMS)" : "ONLINE (APP)"}
  `;

  if (isOffline) {
    systemPrompt += `
    OFFLINE MODE RULES:
    - You are communicating via SMS. You do NOT have the user's GPS coordinates.
    - If the user is in "stalking", "abuse", or "danger", first ask for their current location or a nearby landmark.
    - Once provided, give clear textual directions to the nearest Police Station/Hospital/Shelter based on your knowledge of Mumbai.
    - Example: "If you are near Bandra Station, head West on S.V. Road — Bandra Police Station is about 5 minutes away."
    - Always use landmarks and street names since they cannot use maps.
    `;
  } else {
    systemPrompt += `
    ONLINE APP MODE RULES:
    - If category is "stalking", "abuse", or "danger", a "Safe Havens" card is already shown on screen. Reference it naturally (e.g., "I've found some safe spots near you on your screen.").
    - Only suggest using the SOS button if Risk Level is "high" AND the situation is clearly confirmed dangerous.
    - NEVER ask for the user's location — you already have live GPS context.
    `;
  }

  try {
    const response = await axios.post("https://openrouter.ai/api/v1/chat/completions", {
      model: "openai/gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        ...history.map(m => ({
          role: m.user ? "user" : "assistant",
          content: m.user || m.bot
        })),
        { role: "user", content: userMessage }
      ]
    }, {
      headers: {
        "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
        "Content-Type": "application/json"
      }
    });

    return response.data.choices[0].message.content;
  } catch (error) {
    console.error("❌ OpenRouter Error Details:", error.response?.data || error.message);
    return fallbackResponses[category] || fallbackResponses.general;
  }
}

async function processChatMessage(userId, message, isOffline = false) {
  if (!userSessions[userId]) {
    userSessions[userId] = {
      lastRisk: null,
      lastCategory: null,
      history: [],
      messageCount: 0
    };
  }

  userSessions[userId].messageCount++;
  const msgCount = userSessions[userId].messageCount;

  // 1. Detect and Translate for BERT (if not English)
  const englishMessage = await translateToEnglish(message);

  // 2. Predict Risk with BERT ML Model
  let risk = "low";
  try {
    const response = await axios.post("http://127.0.0.1:8000/predict", { text: englishMessage });
    risk = response.data.risk;
    if (response.data.emotion === "happy" || response.data.emotion === "positive") {
      risk = "low";
    }
  } catch (error) {
    console.log("ML API error:", error.message);
  }

  const category = detectCategory(message);
  
  // Natural escalation logic
  if (["stalking", "abuse", "danger", "harassment"].includes(category)) {
    if (msgCount === 1 && risk === "high") {
        risk = "medium"; // Soften the very first interaction
    } else {
        risk = "high";
    }
  }

  // 2. Generate Context-Aware Reply using LLM (Generative AI)
  const reply = await getGenerativeReply(userId, message, category, risk, isOffline);

  // 3. Translate Jarvis's reply back to English for the UI/translation record if necessary
  let replyTranslation = null;
  if (!/^[\x00-\x7F]*$/.test(reply)) {
    replyTranslation = await translateToEnglish(reply);
    // Note: If translateToEnglish was called on something already translated, it would stay same, 
    // but here we are translating TO English, so it works.
  }

  // 4. Determine Actions/UI based on Risk Tier
  let action = "none";
  let ui = "green";

  if (risk === "high") {
    ui = "red";
    if (category === "stalking") {
      action = "notify_following";
    } else {
      action = "trigger_sos"; // Immediate escalation
    }
  } else if (risk === "medium") {
    ui = "yellow";
    // Suggest safe places or share location based on category
    if (["stalking", "abuse", "danger"].includes(category)) {
      action = "show_safe_places";
    } else {
      action = "share_location";
    }
  } else {
    // Low risk: pure conversation, but show safe places proactively for specific threats
    ui = "green";
    if (["stalking", "abuse", "danger", "harassment"].includes(category)) {
      action = category === "harassment" ? "collect_evidence" : "show_safe_places";
    } else {
      action = "none";
    }
  }

  // Final cross-check: If safe places are being shown, make sure LLM knows it.
  // We re-run generative reply with this knowledge if necessary, 
  // but for now, we'll just return the current reply.

  // Update session
  userSessions[userId].lastRisk = risk;
  userSessions[userId].lastCategory = category;
  userSessions[userId].history.push({ user: message }, { bot: reply });

  return { 
    reply, 
    replyTranslation: replyTranslation,
    userTranslation: englishMessage !== message ? englishMessage : null, 
    action, 
    ui, 
    risk, 
    category 
  };
}

module.exports = {
  processChatMessage
};
