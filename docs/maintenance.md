# Maintenance & Operations Guide

This guide details operational guidelines for maintaining TrackX.

## Hotfix Process

Urgent patches (e.g. v1.0.1) should follow this sequence:
1. Create patch branch: `git checkout -b hotfix/issue-name`.
2. Implement regression unit tests.
3. Apply code fix and verify formatting: `dart format .`.
4. Validate static analysis: `flutter analyze`.
5. Run test suite: `flutter test`.
6. Compile signed APK: `flutter build apk --release`.

## Database Schema Migrations

Every time local Hive/Isar data structures change:
1. Increment the database schema version constant.
2. Code matching migration mapper blocks.
3. Test migration flows from previous app versions.

## Security Secrets Rotation

If any API key or Firebase server token is leaked:
1. Revoke the credential inside the Google Cloud Console / Firebase Console immediately.
2. Provision a new secret.
3. Update environment secrets in Google Cloud Secret Manager / GitHub Secrets.
4. Verify deployment rules.
