const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function testFirestore() {
  try {
    console.log("Testing Firestore connection...");
    const snapshot = await db.collection('users').limit(1).get();
    console.log("Success! Found " + snapshot.docs.length + " documents.");
  } catch (error) {
    console.error("Firestore Error:", error);
  }
}

testFirestore();
