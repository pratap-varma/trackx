# Institution Provider Integration Guide

This guide details how to implement official API connections for universities.

## Provider Interface

All university connection connectors must implement the `InstitutionIntegrationProvider` contract:

```dart
abstract class InstitutionIntegrationProvider {
  Future<bool> authenticate(String authUrl);
  Future<List<Course>> fetchCourses(String accessToken);
  Future<List<AttendanceEntry>> fetchAttendance(String accessToken, String courseId);
}
```

## Security Requirements

1. **OAuth2 with PKCE**: Implicit flow is strictly prohibited.
2. **Platform Secure Storage**: Access tokens must be stored inside Keychain (iOS) and KeyStore (Android). SharedPreferences is blocked.
3. **Read-Only Enforcement**: Providers must not submit mock attendance entries back to the server.
