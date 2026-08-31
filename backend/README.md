# TrackX Backend — Firebase Admin SDK Scripts

This directory contains **server-side only** scripts that use the Firebase Admin SDK.

> [!CAUTION]
> **Never place these scripts or the service-account key inside `lib/`, `assets/`, or anywhere in the Flutter project that is bundled into the APK.**

---

## Prerequisites

### 1. Node.js
Ensure Node.js ≥ 18 is installed:
```bash
node --version
```

### 2. Install dependencies
From the project root (where `package.json` is located):
```bash
npm install
```

### 3. Service Account Key (Required)
The scripts require Firebase Admin credentials.

**Download your service account key:**
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Go to: **Project Settings** → **Service Accounts** tab
3. Click **"Generate new private key"**
4. Save the downloaded `.json` file as **`backend/serviceAccountKey.json`**

> ⚠️ **`serviceAccountKey.json` is listed in `.gitignore` and must NEVER be committed to Git.**

Alternatively, set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
```

---

## Scripts

### `set-role.js` — Assign role by Firebase UID

```bash
node backend/set-role.js <UID> <role>
```

**Supported roles:** `student` | `faculty` | `admin`

**Examples:**
```bash
# Grant admin access
node backend/set-role.js abc123XYZ789 admin

# Set/reset to student
node backend/set-role.js abc123XYZ789 student

# Set faculty role
node backend/set-role.js abc123XYZ789 faculty
```

**How to find a UID:**
- Firebase Console → Authentication → Users → copy the "User UID" column

---

### `set-role-by-email.js` — Assign role by email address

More convenient — looks up the UID automatically:

```bash
node backend/set-role-by-email.js <email> <role>
```

**Examples:**
```bash
# Grant admin to the initial administrator
node backend/set-role-by-email.js pratapuppalaati6@gmail.com admin

# Revoke admin (set back to student)
node backend/set-role-by-email.js pratapuppalaati6@gmail.com student
```

**Expected output:**
```
Using local service-account key.

Firebase user found:
  Email: pratapuppalaati6@gmail.com
  UID:   <firebase-user-uid>
  Name:  Pratap

Role assigned successfully:
  role = admin
  Full claims: {"role":"admin"}

⚠️  The user must refresh their Firebase ID token before the new
   role appears in the TrackX application.
   They can do this by:
     - Signing out and signing back in, or
     - The app will auto-refresh when navigating to the admin panel.
```

---

## How Token Refresh Works

Firebase Custom Claims are stored inside the **Firebase ID Token** (a JWT).

Tokens are cached locally and valid for **1 hour**. A role change does not appear until the token is refreshed.

### Ways to refresh:
1. **Sign out and sign back in** — always gets fresh token
2. **TrackX auto-refresh** — the Admin Dashboard calls `getIdToken(true)` when opened
3. **Programmatic** — call `FirebaseAuth.instance.currentUser?.getIdToken(true)`

---

## Security Architecture

```
Firebase Console / Backend Script
         │
         ▼
Firebase Admin SDK (server only)
         │
         ▼
Firebase Authentication
Custom Claims: { "role": "admin" }
         │
         ▼
Firebase ID Token (JWT, refreshed every hour)
         │
         ▼
TrackX Flutter App reads:
  getIdTokenResult().claims['role']
         │
         ▼
Firestore Security Rules enforce:
  request.auth.token.role == 'admin'
```

**The Flutter app client cannot assign itself the admin role:**
- `getIdTokenResult()` reads the token from Firebase servers
- Firebase Security Rules run server-side — the client cannot bypass them
- The Admin SDK credential is never embedded in the app

---

## Firestore Security Rules

Admin-protected resources use:
```javascript
request.auth != null && request.auth.token.role == "admin"
```

---

## Testing Roles

| Role | Admin Dashboard | Normal TrackX | Notes |
|------|----------------|---------------|-------|
| `admin` | ✅ Full access | ✅ Normal access | Can access `/admin` |
| `faculty` | ❌ Redirected | ✅ Normal access | Future role |
| `student` | ❌ Redirected | ✅ Normal access | Default role |
| (no claim) | ❌ Redirected | ✅ Normal access | Treated as student |
