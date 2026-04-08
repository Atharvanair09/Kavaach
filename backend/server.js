require("dotenv").config({ path: "../.env" });
const express = require("express");
const cors = require("cors");

const chatRoute = require("./routes/chat");
const authRoute = require("./routes/auth");
const sosRoute = require("./routes/sos");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/chat", chatRoute);
app.use("/auth", authRoute);
app.use("/sos", sosRoute);


const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => { 
  console.log("Kavaach backend listening on ALL interfaces on port " + PORT);
});