const { db } = require("./firebase.js");

const defaultLocations = [
  // ─────────────────────────────────────────────
  // 🚔 POLICE STATIONS
  // ─────────────────────────────────────────────
  {
    name: "Colaba Police Station",
    type: "police",
    latitude: 18.9223,
    longitude: 72.8311,
    contact: "022-22151493"
  },
  {
    name: "Azad Maidan Police Station",
    type: "police",
    latitude: 18.9419,
    longitude: 72.8347,
    contact: "022-22620697"
  },
  {
    name: "Agripada Police Station",
    type: "police",
    latitude: 18.9636,
    longitude: 72.8198,
    contact: "022-23078213"
  },
  {
    name: "Byculla Police Station",
    type: "police",
    latitude: 18.9736,
    longitude: 72.8376,
    contact: "022-23027917"
  },
  {
    name: "Dadar Police Station",
    type: "police",
    latitude: 19.0186,
    longitude: 72.8432,
    contact: "022-24323044"
  },
  {
    name: "Dharavi Police Station",
    type: "police",
    latitude: 19.0429,
    longitude: 72.8554,
    contact: "022-24015767"
  },
  {
    name: "Bandra Police Station",
    type: "police",
    latitude: 19.0601,
    longitude: 72.8366,
    contact: "022-26423021"
  },
  {
    name: "Andheri (East) Police Station",
    type: "police",
    latitude: 19.1174,
    longitude: 72.8757,
    contact: "022-26831562"
  },
  {
    name: "Juhu Police Station",
    type: "police",
    latitude: 19.1044,
    longitude: 72.8268,
    contact: "022-26715000"
  },
  {
    name: "Malad (West) Police Station",
    type: "police",
    latitude: 19.1865,
    longitude: 72.8479,
    contact: "022-28821482"
  },
  {
    name: "Kandivali (West) Police Station",
    type: "police",
    latitude: 19.2061,
    longitude: 72.8425,
    contact: "022-28012331"
  },
  {
    name: "Borivali Police Station",
    type: "police",
    latitude: 19.2316,
    longitude: 72.8567,
    contact: "022-28092331"
  },
  {
    name: "Dahisar Police Station",
    type: "police",
    latitude: 19.2528,
    longitude: 72.8567,
    contact: "022-28284024"
  },
  {
    name: "Ghatkopar Police Station",
    type: "police",
    latitude: 19.0858,
    longitude: 72.9083,
    contact: "022-25012333"
  },
  {
    name: "Kurla Police Station",
    type: "police",
    latitude: 19.0656,
    longitude: 72.8801,
    contact: "022-25237000"
  },
  {
    name: "Worli Police Station",
    type: "police",
    latitude: 19.0130,
    longitude: 72.8172,
    contact: "022-24955626"
  },
  {
    name: "Cuffe Parade Police Station",
    type: "police",
    latitude: 18.9138,
    longitude: 72.8235,
    contact: "022-22163200"
  },
  {
    name: "Sion Police Station",
    type: "police",
    latitude: 19.0393,
    longitude: 72.8622,
    contact: "022-24074575"
  },
  {
    name: "Chembur Police Station",
    type: "police",
    latitude: 19.0625,
    longitude: 72.9007,
    contact: "022-25229345"
  },
  {
    name: "Powai Police Station",
    type: "police",
    latitude: 19.1180,
    longitude: 72.9060,
    contact: "022-25702690"
  },
  {
    name: "Women's Helpline Control Room",
    type: "police",
    latitude: 18.9419,
    longitude: 72.8347,
    contact: "103"
  },

  // ─────────────────────────────────────────────
  // 🏥 HOSPITALS & CLINICS
  // ─────────────────────────────────────────────

  {
    name: "KEM Hospital (Parel)",
    type: "hospital",
    latitude: 18.9991,
    longitude: 72.8408,
    contact: "022-24107000"
  },
  {
    name: "Sir J.J. Hospital (Byculla)",
    type: "hospital",
    latitude: 18.9641,
    longitude: 72.8354,
    contact: "022-23735555"
  },
  {
    name: "BYL Nair Hospital (Mumbai Central)",
    type: "hospital",
    latitude: 18.9706,
    longitude: 72.8196,
    contact: "022-23027600"
  },
  {
    name: "Sion Hospital - LTMG (Sion)",
    type: "hospital",
    latitude: 19.0393,
    longitude: 72.8644,
    contact: "022-24076381"
  },
  {
    name: "Cooper Hospital (Vile Parle)",
    type: "hospital",
    latitude: 19.1027,
    longitude: 72.8491,
    contact: "022-26207254"
  },
  {
    name: "Kasturba Hospital (Chinchpokli)",
    type: "hospital",
    latitude: 18.9736,
    longitude: 72.8312,
    contact: "022-23081500"
  },
  {
    name: "Rajawadi Hospital (Ghatkopar East)",
    type: "hospital",
    latitude: 19.0780,
    longitude: 72.9113,
    contact: "022-25018000"
  },
  {
    name: "Bhabha Hospital (Bandra West)",
    type: "hospital",
    latitude: 19.0523,
    longitude: 72.8337,
    contact: "022-26402273"
  },
  {
    name: "Bhagwati Hospital (Borivali West)",
    type: "hospital",
    latitude: 19.2282,
    longitude: 72.8519,
    contact: "022-28954747"
  },
  {
    name: "GT Hospital (Fort)",
    type: "hospital",
    latitude: 18.9383,
    longitude: 72.8350,
    contact: "022-22621427"
  },
  {
    name: "Tata Memorial Hospital (Parel)",
    type: "hospital",
    latitude: 19.0041,
    longitude: 72.8427,
    contact: "022-24177000"
  },
  {
    name: "V.N. Desai Hospital (Santacruz East)",
    type: "hospital",
    latitude: 19.0819,
    longitude: 72.8554,
    contact: "022-26188080"
  },
  {
    name: "Trauma Care Centre - Jogeshwari",
    type: "hospital",
    latitude: 19.1390,
    longitude: 72.8490,
    contact: "022-26781234"
  },

  // ─────────────────────────────────────────────
  // 🏠 SHELTERS (Homeless & Abuse)
  // ─────────────────────────────────────────────

  {
    name: "SNEHA Crisis Centre (Santa Cruz West)",
    type: "shelter",
    latitude: 19.0830,
    longitude: 72.8390,
    contact: "9892278287"
  },
  {
    name: "Shantighar Shelter for Women (Andheri East)",
    type: "shelter",
    latitude: 19.1174,
    longitude: 72.8757,
    contact: "022-28348400"
  },
  {
    name: "Urja Trust - Shelter for Homeless Women (Dadar East)",
    type: "shelter",
    latitude: 19.0186,
    longitude: 72.8508,
    contact: "022-24125678"
  },
  {
    name: "Bapnu Ghar - Women in Distress (Worli)",
    type: "shelter",
    latitude: 19.0130,
    longitude: 72.8172,
    contact: "022-24950000"
  },
  {
    name: "Apne Aap - Women Empowerment (Grant Road)",
    type: "shelter",
    latitude: 18.9641,
    longitude: 72.8183,
    contact: "022-23800000"
  },
  {
    name: "Daya Sadan - Society of Helpers of Mary (Dharavi)",
    type: "shelter",
    latitude: 19.0429,
    longitude: 72.8554,
    contact: "022-24016780"
  },
  {
    name: "Kranti - Girls from Difficult Circumstances (Kurla East)",
    type: "shelter",
    latitude: 19.0656,
    longitude: 72.8801,
    contact: "022-25236789"
  },
  {
    name: "SPARC Shelter (Byculla)",
    type: "shelter",
    latitude: 18.9736,
    longitude: 72.8376,
    contact: "022-23026000"
  },
  {
    name: "Salvation Army - Bombay Central",
    type: "shelter",
    latitude: 18.9706,
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