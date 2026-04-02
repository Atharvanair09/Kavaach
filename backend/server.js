require("dotenv").config({ path: "../.env" });
const express = require("express");
const cors = require("cors");

const chatRoute = require("./routes/chat");
const authRoute = require("./routes/auth");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/chat", chatRoute);
app.use("/auth", authRoute);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log("Kavaach backend running on port " + PORT);
});