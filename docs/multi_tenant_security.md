# Multi-Tenant Security Standards

This document outlines structural tenant isolation requirements.

## Tenant Isolation Rules

1. **Server-Side Enforcement**: Client filtering is used only for UI formatting. Backend APIs must validate access.
2. **Database Boundaries**: Queries must explicitly include the `institutionId` parameter.
3. **Storage Access**: Restrict file upload buckets access using Firebase Storage rules matching membership.
