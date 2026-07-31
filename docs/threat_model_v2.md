# Threat Model v2

This document details the security threat model for the v2.0 multi-tenant upgrade.

## Threat Analysis

1. **Cross-Tenant Access Bypass**:
   - *Risk*: A student or administrator reads records belonging to another institution.
   - *Mitigation*: Enforce server-side rules checking `request.auth.token.institutionId == resource.data.institutionId`.

2. **Role Escalation**:
   - *Risk*: Student tampers with client-side flags to gain administrator dashboard scopes.
   - *Mitigation*: Authenticate roles using Firebase Custom Claims or backend database checks.

3. **QR Code Replay**:
   - *Risk*: Attendance codes screenshotted and shared online.
   - *Mitigation*: Limit code lifespan to 60 seconds with unique nonces.
