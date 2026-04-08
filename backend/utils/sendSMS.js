const axios = require("axios");

/**
 * Sends an SMS via TextBee API.
 * @param {string} to - Recipient phone number with country code (e.g. "+919876543210")
 * @param {string} message - The SMS message body
 */
async function sendSMS(to, message) {
  const apiKey = process.env.TEXTBEE_API_KEY;
  const deviceId = process.env.TEXTBEE_DEVICE_ID;

  if (!apiKey) {
    throw new Error("TEXTBEE_API_KEY is not set in environment variables.");
  }

  console.log(`📱 Sending SMS to ${to} via TextBee...`);

  try {
    const response = await axios.post(
      `https://api.textbee.dev/api/v1/gateway/devices/${deviceId}/sendSMS`,
      {
        recipients: [to],
        message: message,
      },
      {
        headers: {
          "x-api-key": apiKey,
          "Content-Type": "application/json",
        },
      }
    );

    console.log(`✅ SMS sent to ${to}:`, response.data);
    return response.data;
  } catch (error) {
    const errMsg = error.response?.data || error.message;
    console.error(`❌ Failed to send SMS to ${to}:`, errMsg);
    throw new Error(`TextBee SMS failed: ${JSON.stringify(errMsg)}`);
  }
}

module.exports = sendSMS;
