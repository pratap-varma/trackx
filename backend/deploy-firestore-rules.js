const { initializeApp, cert } = require('firebase-admin/app');
const { getSecurityRules } = require('firebase-admin/security-rules');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const source = `
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
`;

async function deployRules() {
  try {
    console.log("Deploying Firestore Security Rules...");
    const rulesFile = getSecurityRules().createRulesFileFromSource('firestore.rules', source);
    const ruleset = await getSecurityRules().createRuleset(rulesFile);
    
    await getSecurityRules().releaseFirestoreRuleset(ruleset.name);
    console.log("Successfully deployed Firestore rules!");
  } catch (error) {
    console.error("Error deploying rules:", error);
  }
}

deployRules();
