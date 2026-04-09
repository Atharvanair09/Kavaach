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
  if (/(stalk|follow|someone behind|watching|police|station)/.test(text)) return "stalking";
  if (/(abuse|violence|hit|beat|hurt|assault)/.test(text)) return "abuse";
  if (/(danger|unsafe|scared|help|shelter|hospital|location|address)/.test(text)) return "danger";
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
    You are Jarvis, a personal safety assistant for women in distress, integrated into the Kavaach app. You are OPERATING IN INDIA.

    RULES:
    1. NEVER repeat the same response twice.
    2. ALWAYS give the user OPTIONS, not instructions. Do not pressure them to leave immediately — that can be dangerous.
    3. If the user mentions physical violence, abuse, or being hit:
       - First validate their feelings with empathy.
       - Acknowledge the seriousness immediately.
       - Provide actionable next steps.
       - Mention relevant helplines (iCall: 9152987821, Women's helpline: 181).
    4. After 1-2 follow-up questions, ALWAYS move toward offering help.
    5. Do not keep asking "tell me more" repeatedly — that feels dismissive.
    6. If danger seems immediate, prioritize safety steps first, especially if children are mentioned.
    7. Always keep SOS as an available action and mention it if appropriate.
    8. End every response with an open question OR a clear next step.
    9. Keep replies concise (under 3 sentences) and subtle/covert.
    10. IMPORTANT: If the category is "stalking", "abuse", or "danger", I am showing a "Safe Havens" card under your message with nearby police/shelters. Reference these places in your response (e.g., "I've identified some safe spots nearby on your screen").
    11. NEVER ask the user for their location or city. You ALREADY have their live GPS coordinates and nearby places in the CURRENT CONTEXT. Use this information to guide them directly.

    RESPONSE FORMAT for abuse situations:
    - Line 1: Validate (e.g., "That is not okay. You don't deserve this.")
    - Line 2: Assess safety (e.g., "Are you safe right now? Is he still there?")
    - Line 3: Offer next step (e.g., "I can help you find a shelter or contact someone.")

    CURRENT CONTEXT:
    - User Message Count: ${msgCount}
    - Detected Category: ${category}
    - Risk Level: ${risk}
  `;

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

  // 3. Determine Actions/UI based on Risk Tier
  let action = "none";
  let ui = "green";

  if (risk === "high") {
    ui = "red";
    action = "trigger_sos"; // Immediate escalation
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
    if (["stalking", "abuse", "danger"].includes(category)) {
      action = "show_safe_places";
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

  return { reply, action, ui, risk, category };
}

module.exports = {
  processChatMessage
};
