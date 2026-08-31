/// UserRole — Firebase Custom Claims role model for TrackX
///
/// The authoritative source is always the Firebase ID Token custom claim:
///   `{ "role": "admin" | "faculty" | "student" }`
///
/// Flutter reads: `getIdTokenResult().claims?['role']`
/// Firestore rules enforce: `request.auth.token.role == "admin"`
///
/// IMPORTANT: The default/fallback is always [UserRole.student] — the
/// least-privileged role. An error or missing claim must NEVER result
/// in admin access being granted.
enum UserRole {
  /// Standard student user. Default role. Least privileged.
  student,

  /// Faculty/teacher role. Reserved for future use.
  faculty,

  /// Administrator. Can access the Admin Dashboard and admin-protected
  /// Firestore resources. Requires Custom Claim: `{ "role": "admin" }`
  admin,
}

/// Parse a Firebase Custom Claim value into a [UserRole].
///
/// Safely defaults to [UserRole.student] for:
/// - null values (claim not present)
/// - unknown strings
/// - non-string types
/// - any error
///
/// This fail-safe ensures an invalid or missing claim never grants elevated
/// privileges.
UserRole parseUserRole(dynamic value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'faculty':
      return UserRole.faculty;
    case 'student':
      return UserRole.student;
    default:
      // Unknown, null, or malformed value → least privileged
      return UserRole.student;
  }
}
