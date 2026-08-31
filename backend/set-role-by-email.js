/**
 * TrackX — Firebase Custom Claims Role Management (Email-Based)
 *
 * Compatible with firebase-admin v12+ (modular API)
 *
 * USAGE:
 *   node backend/set-role-by-email.js <email> <role>
 *
 * EXAMPLES:
 *   node backend/set-role-by-email.js pratapuppalaati6@gmail.com admin
 *   node backend/set-role-by-email.js user@example.com student
 *   node backend/set-role-by-email.js teacher@example.com faculty
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
const [, , email, role] = process.argv;

if (!email || !role) {
  console.error('\nUsage: node backend/set-role-by-email.js <email> <role>');
  console.error('Roles:  student | faculty | admin\n');
  process.exit(1);
}

if (!VALID_ROLES.includes(role)) {
  console.error(`\nInvalid role: "${role}"`);
  console.error(`Valid roles: ${VALID_ROLES.join(', ')}\n`);
  process.exit(1);
}

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(email)) {
  console.error(`\nInvalid email format: "${email}"\n`);
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

// ─── Main: look up user by email and assign role ─────────────────────────────
async function setRoleByEmail(targetEmail, targetRole) {
  console.log(`\nLooking up Firebase user by email: ${targetEmail}`);

  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(targetEmail);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.error(`\nError: No Firebase Authentication user found with email: ${targetEmail}`);
      console.error('Verify the email is registered in Firebase Console → Authentication → Users.\n');
    } else {
      console.error(`\nError retrieving user: ${err.message}\n`);
    }
    process.exit(1);
  }

  console.log('\nFirebase user found:');
  console.log(`  Email: ${userRecord.email}`);
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

setRoleByEmail(email, role).catch((err) => {
  console.error(`\nUnexpected error: ${err.message}\n`);
  process.exit(1);
});
