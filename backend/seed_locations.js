const { db } = require("./firebase.js");

const defaultLocations = [
  {
    name: "Colaba Police Station",
    type: "police",
    latitude: 18.9067,
    longitude: 72.8147,
    contact: "022-22151493"
  },
  {
    name: "Azad Maidan Police Station",
    type: "police",
    latitude: 18.9388,
    longitude: 72.8333,
    contact: "022-22620697"
  },
  {
    name: "Agripada Police Station",
    type: "police",
    latitude: 18.9620,
    longitude: 72.8191,
    contact: "022-23078213"
  },
  {
    name: "Byculla Police Station",
    type: "police",
    latitude: 18.9726,
    longitude: 72.8368,
    contact: "022-23027917"
  },
  {
    name: "Dadar Police Station",
    type: "police",
    latitude: 19.0178,
    longitude: 72.8478,
    contact: "022-24323044"
  },
  {
    name: "Dharavi Police Station",
    type: "police",
    latitude: 19.0387,
    longitude: 72.8536,
    contact: "022-24015767"
  },
  {
    name: "Bandra Police Station",
    type: "police",
    latitude: 19.0540,
    longitude: 72.8393,
    contact: "022-26423021"
  },
  {
    name: "Andheri (East) Police Station",
    type: "police",
    latitude: 19.1136,
    longitude: 72.8697,
    contact: "022-26831562"
  },
  {
    name: "Juhu Police Station",
    type: "police",
    latitude: 19.1075,
    longitude: 72.8263,
    contact: "022-26715000"
  },
  {
    name: "Malad (West) Police Station",
    type: "police",
    latitude: 19.1874,
    longitude: 72.8484,
    contact: "022-28821482"
  },
  {
    name: "Kandivali (West) Police Station",
    type: "police",
    latitude: 19.2050,
    longitude: 72.8457,
    contact: "022-28012331"
  },
  {
    name: "Borivali Police Station",
    type: "police",
    latitude: 19.2286,
    longitude: 72.8567,
    contact: "022-28092331"
  },
  {
    name: "Dahisar Police Station",
    type: "police",
    latitude: 19.2183,
    longitude: 72.8697,
    contact: "022-28284024"
  },
  {
    name: "Ghatkopar Police Station",
    type: "police",
    latitude: 19.0863,
    longitude: 72.9076,
    contact: "022-25012333"
  },
  {
    name: "Kurla Police Station",
    type: "police",
    latitude: 19.0653,
    longitude: 72.8807,
    contact: "022-25237000"
  },
  {
    name: "Worli Police Station",
    type: "police",
    latitude: 19.0069,
    longitude: 72.8181,
    contact: "022-24955626"
  },
  {
    name: "Cuffe Parade Police Station",
    type: "police",
    latitude: 18.9040,
    longitude: 72.8191,
    contact: "022-22163200"
  },
  {
    name: "Sion Police Station",
    type: "police",
    latitude: 19.0416,
    longitude: 72.8615,
    contact: "022-24074575"
  },
  {
    name: "Chembur Police Station",
    type: "police",
    latitude: 19.0522,
    longitude: 72.9005,
    contact: "022-25229345"
  },
  {
    name: "Powai Police Station",
    type: "police",
    latitude: 19.1197,
    longitude: 72.9050,
    contact: "022-25702690"
  },
  {
    name: "Women's Helpline Control Room",
    type: "police",
    latitude: 18.9388,
    longitude: 72.8351,
    contact: "103"
  },

  // ─────────────────────────────────────────────
  // 🏥 HOSPITALS & CLINICS
  // ─────────────────────────────────────────────

  {
    name: "KEM Hospital (Parel)",
    type: "hospital",
    latitude: 19.0013,
    longitude: 72.8413,
    contact: "022-24107000"
  },
  {
    name: "Sir J.J. Hospital (Byculla)",
    type: "hospital",
    latitude: 18.9627,
    longitude: 72.8350,
    contact: "022-23735555"
  },
  {
    name: "BYL Nair Hospital (Mumbai Central)",
    type: "hospital",
    latitude: 18.9699,
    longitude: 72.8196,
    contact: "022-23027600"
  },
  {
    name: "Sion Hospital - LTMG (Sion)",
    type: "hospital",
    latitude: 19.0407,
    longitude: 72.8617,
    contact: "022-24076381"
  },
  {
    name: "Cooper Hospital (Vile Parle)",
    type: "hospital",
    latitude: 19.1075,
    longitude: 72.8381,
    contact: "022-26207254"
  },
  {
    name: "Kasturba Hospital (Chinchpokli)",
    type: "hospital",
    latitude: 18.9726,
    longitude: 72.8305,
    contact: "022-23081500"
  },
  {
    name: "Rajawadi Hospital (Ghatkopar East)",
    type: "hospital",
    latitude: 19.0761,
    longitude: 72.9120,
    contact: "022-25018000"
  },
  {
    name: "Bhabha Hospital (Bandra West)",
    type: "hospital",
    latitude: 19.0607,
    longitude: 72.8362,
    contact: "022-26402273"
  },
  {
    name: "Bhagwati Hospital (Borivali West)",
    type: "hospital",
    latitude: 19.2313,
    longitude: 72.8503,
    contact: "022-28954747"
  },
  {
    name: "GT Hospital (Fort)",
    type: "hospital",
    latitude: 18.9366,
    longitude: 72.8349,
    contact: "022-22621427"
  },
  {
    name: "Tata Memorial Hospital (Parel)",
    type: "hospital",
    latitude: 19.0041,
    longitude: 72.8430,
    contact: "022-24177000"
  },
  {
    name: "V.N. Desai Hospital (Santacruz East)",
    type: "hospital",
    latitude: 19.0822,
    longitude: 72.8559,
    contact: "022-26188080"
  },
  {
    name: "Trauma Care Centre - Jogeshwari",
    type: "hospital",
    latitude: 19.1378,
    longitude: 72.8494,
    contact: "022-26781234"
  },

  // ─────────────────────────────────────────────
  // 🏠 SHELTERS (Homeless & Abuse)
  // ─────────────────────────────────────────────

  {
    name: "SNEHA Crisis Centre (Santa Cruz West)",
    type: "shelter",
    latitude: 19.0822,
    longitude: 72.8386,
    contact: "9892278287"
  },
  {
    name: "Shantighar Shelter for Women (Andheri East)",
    type: "shelter",
    latitude: 19.1162,
    longitude: 72.8727,
    contact: "022-28348400"
  },
  {
    name: "Urja Trust - Shelter for Homeless Women (Dadar East)",
    type: "shelter",
    latitude: 19.0194,
    longitude: 72.8505,
    contact: "022-24125678"
  },
  {
    name: "Bapnu Ghar - Women in Distress (Worli)",
    type: "shelter",
    latitude: 19.0069,
    longitude: 72.8191,
    contact: "022-24950000"
  },
  {
    name: "Apne Aap - Women Empowerment (Grant Road)",
    type: "shelter",
    latitude: 18.9640,
    longitude: 72.8178,
    contact: "022-23800000"
  },
  {
    name: "Daya Sadan - Society of Helpers of Mary (Dharavi)",
    type: "shelter",
    latitude: 19.0387,
    longitude: 72.8536,
    contact: "022-24016780"
  },
  {
    name: "Kranti - Girls from Difficult Circumstances (Kurla East)",
    type: "shelter",
    latitude: 19.0653,
    longitude: 72.8807,
    contact: "022-25236789"
  },
  {
    name: "SPARC Shelter (Byculla)",
    type: "shelter",
    latitude: 18.9726,
    longitude: 72.8368,
    contact: "022-23026000"
  },
  {
    name: "Salvation Army - Bombay Central",
    type: "shelter",
    latitude: 18.9699,
    longitude: 72.8225,
    contact: "022-23096000"
  }
];

async function seedData() {
  if (!db) {
    console.error("Firestore not initialized. Check your serviceAccountKey.json");
    return;
  }

  console.log("Adding locations to Firestore...");
  const collectionRef = db.collection("safe_havens");

  for (const loc of defaultLocations) {
    await collectionRef.add(loc);
    console.log(`✅ Added: ${loc.name}`);
  }
  
  console.log("🎉 Seeding complete. You can view them in the Firebase Console.");
  process.exit(0);
}

seedData();
