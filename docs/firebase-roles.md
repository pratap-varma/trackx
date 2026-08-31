# TrackX — Firebase Custom Claims Role System

## Overview

TrackX uses **Firebase Custom Claims** as the authoritative source for role-based access control. Claims are set by the Firebase Admin SDK (server-side only) and are embedded inside Firebase ID Tokens (JWTs).

The Flutter client reads claims from `getIdTokenResult()` — it **cannot** modify them. Firebase Security Rules enforce permissions server-side.

---

## Available Roles

| Role | Value in Claim | Access Level |
|------|---------------|--------------|
| Student | `"student"` | Normal TrackX features |
| Faculty | `"faculty"` | Reserved for future use |
| Admin | `"admin"` | Admin Dashboard + all Firestore admin resources |

**Default (no claim):** `student` — the least-privileged role. Any missing, null, or unknown claim defaults to student. An error can never result in admin access being granted.

---

## Claim Format

```json
{
  "role": "admin"
}
```

NOT:
```json
{
  "admin": true,
  "isAdmin": true
}
```

---

## Setup

### Prerequisites

1. Node.js ≥ 18
2. From the project root: `npm install`
3. Firebase service-account key at `backend/serviceAccountKey.json`
   - Download: Firebase Console → Project Settings → Service Accounts → Generate new private key
   - **Never commit this file to Git** (it is in `.gitignore`)

---

## Assigning the Admin Role

### Step 1: Get the Firebase UID

Option A — by email (easier):
```bash
node backend/set-role-by-email.js pratapuppalaati6@gmail.com admin
```

Option B — by UID (from Firebase Console → Authentication → Users):
```bash
node backend/set-role.js <UID> admin
```

**Expected output:**
```
Firebase user found:
  Email: pratapuppalaati6@gmail.com
  UID:   abc123xyz789

Role assigned successfully:
  role = admin
  Full claims: {"role":"admin"}

⚠️  The user must refresh their Firebase ID Token before the new
   role appears in the TrackX application.
```

### Step 2: Refresh the token

The user must either:
- Sign out and sign back in, OR
- Open the Admin Dashboard (TrackX auto-refreshes when entering admin routes)

---

## Removing the Admin Role

```bash
node backend/set-role-by-email.js pratapuppalaati6@gmail.com student
```

or by UID:
```bash
node backend/set-role.js <UID> student
```

---

## How Flutter Reads the Role

### On login (automatic)
`auth_repository.dart` calls `getIdTokenResult()` once per login and stores the role in `AuthState`:

```dart
final tokenResult = await fbUser.getIdTokenResult();
final role = parseUserRole(tokenResult.claims?['role']);
state = AuthState.authenticated(profile, role: role);
```

### Checking role in widgets
```dart
final authState = ref.watch(authRepositoryProvider);
final isAdmin = authState.isAdmin; // bool
final role = authState.role;       // UserRole enum
```

### Force-refreshing claims
```dart
// After admin role is assigned via the backend script:
await ref.read(authRepositoryProvider.notifier).refreshUserClaims();
```

---

## How the Admin Dashboard is Protected

### Route guard (`app_router.dart`)
The `/admin` route and sub-routes redirect to `/admin/login` unless `adminAuthStateProvider.isAuthenticated` is true.

### `AdminAuthNotifier.checkAdminAuth()` (`admin_providers.dart`)
Calls `AdminRepository.verifyAdminStatus()` on startup.

### `AdminRepository.verifyAdminStatus()` (`admin_repository.dart`)
Checks in order:
1. **Primary:** `claims['role'] == 'admin'` (Firebase Custom Claim — authoritative)
2. **Legacy:** `claims['isAdmin'] == true` (old field — kept during transition)
3. **Fallback:** Firestore `admins/{uid}` document exists (kept during transition)

---

## Firestore Security Rules

```javascript
function isAdmin() {
  return isAuthenticated() && (
    request.auth.token.role == "admin" ||        // primary (Custom Claim)
    request.auth.token.isAdmin == true ||          // legacy fallback
    exists(/databases/.../documents/admins/$(request.auth.uid))  // Firestore fallback
  );
}

// Admin-only collection:
match /admin_settings/{document} {
  allow read, write: if isAdmin();
}

// Activity logs: users can write, only admins can read:
match /activity_logs/{logId} {
  allow create: if isAuthenticated();
  allow read: if isAdmin();
}
```

**The client cannot bypass these rules** even if the Flutter app code is modified.

---

## Token Refresh Behavior

Firebase ID tokens are cached locally and valid for **1 hour**.

| Action | Token refreshed? |
|--------|-----------------|
| Sign out + sign in | ✅ Always fresh |
| `getIdToken(true)` called | ✅ Force refresh |
| `refreshUserClaims()` in auth_repository | ✅ Force refresh |
| Normal app usage (token < 1h old) | ❌ Uses cached token |

The app will not require reinstallation after a role change.

---

## Security Guarantees

1. **Custom Claims are server-only** — only Firebase Admin SDK (backend) can set them
2. **Firestore rules run server-side** — the Flutter client cannot bypass them
3. **No email-based authorization** — `user.email == 'admin@...'` is never used
4. **Fail-safe defaults** — any error defaults to `UserRole.student`
5. **No credential leakage** — `serviceAccountKey.json` is blocked by `.gitignore`
6. **No Admin SDK in the Flutter app** — the service account never touches `lib/`

---

## Testing

### Unit tests
```bash
flutter test test/user_role_test.dart
```

Tests cover:
- `parseUserRole('admin')` → `UserRole.admin`
- `parseUserRole('faculty')` → `UserRole.faculty`
- `parseUserRole('student')` → `UserRole.student`
- `parseUserRole(null)` → `UserRole.student`
- `parseUserRole('')` → `UserRole.student`
- `parseUserRole('unknown')` → `UserRole.student`
- `parseUserRole(true)` → `UserRole.student`
- `parseUserRole({'role': 'admin'})` → `UserRole.student`

### Manual testing

| Scenario | Expected Result |
|----------|----------------|
| Login as `pratapuppalaati6@gmail.com` after running set-role script | Admin Dashboard accessible |
| Login as any normal student | `/admin` redirects to login |
| Open `/admin` URL directly as student | Redirected to `/admin/login` |
| Remove admin role, sign out, sign in again | No Admin Dashboard |

---

## Architecture Summary

```
Firebase Admin SDK (backend/set-role.js)
          │
          ▼
Firebase Authentication — Custom Claim: { "role": "admin" }
          │
          ▼
Firebase ID Token (JWT) — refreshed every hour
          │
          ▼
TrackX Flutter:
  AuthState.role = parseUserRole(claims['role'])
  authState.isAdmin → true/false
          │
          ▼
GoRouter redirect guard (app_router.dart)
  adminAuthStateProvider.isAuthenticated → allow /admin
          │
          ▼
Firestore Security Rules:
  request.auth.token.role == "admin" → allow admin_settings
```
