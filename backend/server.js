require("dotenv").config();
const express = require("express");
const cors = require("cors");

process.on("uncaughtException", (err) => {
  console.error("💥 UNCAUGHT EXCEPTION! Shutting down...");
  console.error(err.name, err.message, err.stack);
  process.exit(1);
});

process.on("unhandledRejection", (err) => {
  console.error("💥 UNHANDLED REJECTION! Shutting down...");
  console.error(err.name, err.message, err.stack);
  process.exit(1);
});


const chatRoute = require("./routes/chat");
const authRoute = require("./routes/auth");
const sosRoute = require("./routes/sos");
const textbeeRoute = require("./routes/textbee");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/chat", chatRoute);
app.use("/auth", authRoute);
app.use("/sos", sosRoute);
app.use("/textbee", textbeeRoute);


const PORT = process.env.PORT || 5000;

try {
  app.listen(PORT, '0.0.0.0', () => { 
    console.log("Kavaach backend listening on ALL interfaces on port " + PORT);
  });
} catch (error) {
  console.error("Failed to start server:", error);
}

// Keep the process alive
setInterval(() => {}, 1000 * 60 * 60);