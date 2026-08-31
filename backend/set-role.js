/**
 * TrackX — Firebase Custom Claims Role Management (UID-Based)
 *
 * Compatible with firebase-admin v12+ (modular API)
 *
 * USAGE:
 *   node backend/set-role.js <UID> <role>
 *
 * EXAMPLES:
 *   node backend/set-role.js abc123xyz789 admin
 *   node backend/set-role.js abc123xyz789 student
 *   node backend/set-role.js abc123xyz789 faculty
 *
 * PREREQUISITES:
 *   Place your service-account key at:  backend/serviceAccountKey.json
 *   Download from: Firebase Console → Project Settings → Service Accounts
 *
 * SECURITY:
 *   serviceAccountKey.json is blocked by .gitignore — NEVER commit it.
 */

'use strict';

// ─── firebase-admin v12+ modular API ────────────────────────────────────────
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const fs = require('fs');
const path = require('path');

// ─── Supported roles ─────────────────────────────────────────────────────────
const VALID_ROLES = ['student', 'faculty', 'admin'];

// ─── Parse CLI arguments ─────────────────────────────────────────────────────
const [, , uid, role] = process.argv;

if (!uid || !role) {
  console.error('\nUsage: node backend/set-role.js <UID> <role>');
  console.error('Roles:  student | faculty | admin\n');
  process.exit(1);
}

if (!VALID_ROLES.includes(role)) {
  console.error(`\nInvalid role: "${role}"`);
  console.error(`Valid roles: ${VALID_ROLES.join(', ')}\n`);
  process.exit(1);
}

// ─── Load service-account key ─────────────────────────────────────────────
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('\nError: serviceAccountKey.json not found.');
  console.error(`Expected location: ${serviceAccountPath}`);
  console.error('\nDownload it from:');
  console.error('  Firebase Console → Project Settings → Service Accounts → Generate new private key\n');
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

// ─── Initialize Firebase Admin SDK (modular v12+ API) ────────────────────────
initializeApp({
  credential: cert(serviceAccount),
});

const auth = getAuth();

// ─── Main: look up user by UID and assign role ────────────────────────────────
async function setRole(targetUid, targetRole) {
  console.log(`\nLooking up Firebase user: ${targetUid}`);

  let userRecord;
  try {
    userRecord = await auth.getUser(targetUid);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.error(`\nError: No Firebase Authentication user found with UID: ${targetUid}`);
      console.error('Check the UID in Firebase Console → Authentication → Users.\n');
    } else {
      console.error(`\nError retrieving user: ${err.message}\n`);
    }
    process.exit(1);
  }

  console.log('\nFirebase user found:');
  console.log(`  Email: ${userRecord.email || '(no email)'}`);
  console.log(`  UID:   ${userRecord.uid}`);
  console.log(`  Name:  ${userRecord.displayName || '(no display name)'}`);

  const existingClaims = userRecord.customClaims || {};
  if (Object.keys(existingClaims).length > 0) {
    console.log(`  Existing claims: ${JSON.stringify(existingClaims)}`);
  }

  // Preserve other claims; set/overwrite the role
  const newClaims = { ...existingClaims, role: targetRole };

  await auth.setCustomUserClaims(userRecord.uid, newClaims);

  console.log(`\nRole assigned successfully:`);
  console.log(`  role = ${targetRole}`);
  console.log(`  Full claims: ${JSON.stringify(newClaims)}`);
  console.log('\n⚠️  The user must refresh their Firebase ID token before the new');
  console.log('   role appears in the TrackX application.');
  console.log('   Sign out and sign back in, or the app will auto-refresh on admin login.\n');
}

setRole(uid, role).catch((err) => {
  console.error(`\nUnexpected error: ${err.message}\n`);
  process.exit(1);
});
