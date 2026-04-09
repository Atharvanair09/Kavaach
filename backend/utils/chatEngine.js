const axios = require("axios");

const userSessions = {};

// Fallback responses in case OpenRouter API fails
const fallbackResponses = {
  stalking: "I understand. Please try to stay in crowded areas and keep someone you trust informed of your location.",
  danger: "Your safety is the priority. Please move to a safe place immediately if you can.",
  general: "I'm here to listen. Tell me more about what's happening."
};

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

async function getGenerativeReply(userId, userMessage, category, risk) {
  const session = userSessions[userId];
  const history = session.history.slice(-6); // Keep last 3 turns
  const msgCount = session.messageCount;

  const systemPrompt = `
    You are Jarvis, a supportive and covert personal safety AI assistant for a safety app called Kavaach.
    
    CURRENT CONTEXT:
    - User Message Count: ${msgCount}
    - Detected Category: ${category}
    - Risk Level (from BERT model): ${risk}
    
    TONE GUIDELINES:
    1. BE CONVERSATIONAL: Acknowledge specific details the user mentions (like locations or feelings).
    2. EMPATHY FIRST: If message count is low (${msgCount} <= 2), focus on filler/calming statements. Don't bark orders yet. Use phrases like "I hear you," "That sounds unsettling," or "I'm here."
    3. ADAPTIVE URGENCY: Only if Risk Level is "high" and message count > 2, provide firm safety instructions. Otherwise, stay supportive and probe for more details.
    4. COVERT: Keep responses subtle. Avoid sounding like a formal emergency bot.
    5. SHORT: Keep replies under 2-3 sentences max.
  `;

  try {
    const response = await axios.post("https://openrouter.ai/api/v1/chat/completions", {
      model: "google/gemma-4-31b-it:free",
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

async function processChatMessage(userId, message) {
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

  // 1. Predict Risk with BERT ML Model
  let risk = "low";
  try {
    const response = await axios.post("http://127.0.0.1:8000/predict", { text: message });
    risk = response.data.risk;
    if (response.data.emotion === "happy" || response.data.emotion === "positive") {
      risk = "low";
    }
  } catch (error) {
    console.log("ML API error:", error.message);
  }

  const category = detectCategory(message);
  
  // Natural escalation logic
  if (["stalking", "abuse", "danger"].includes(category)) {
    if (msgCount === 1 && risk === "high") {
        risk = "medium"; // Soften the very first interaction
    } else {
        risk = "high";
    }
  }

  // 2. Generate Context-Aware Reply using LLM (Generative AI)
  const reply = await getGenerativeReply(userId, message, category, risk);

  // 3. Determine Actions/UI
  let action = "none";
  let ui = "green";

  if (risk === "high" && msgCount >= 2) {
    ui = "red";
    if (userSessions[userId].lastRisk === "high") {
      action = "trigger_sos";
    } else {
      action = "show_safe_places";
    }
  } else if (risk === "medium" || (risk === "high" && msgCount === 1)) {
    ui = "yellow";
    if (category === "stalking" || category === "danger") {
      action = "show_safe_places";
    } else if (msgCount >= 2) {
      action = "share_location";
    }
  }

  // Update session
  userSessions[userId].lastRisk = risk;
  userSessions[userId].lastCategory = category;
  userSessions[userId].history.push({ user: message }, { bot: reply });

  return { reply, action, ui, risk, category };
}

module.exports = {
  processChatMessage
};
