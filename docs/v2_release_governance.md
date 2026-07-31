# Release Governance Framework

This document outlines approvals, emergency-stop authority, and rollback authority.

## Governance Structure

- **Decision Makers**: Release Manager, Lead Security Architect, Privacy Officer.
- **Release Gates**: All critical vulnerabilities resolved; tenant isolation tests passed.
- **Emergency Stop Authority**: Any core member can trigger a halt if a SEV-1 data leakage occurs.
- **Rollback Authority**: Shared approval required to revert Cloud Functions and database schemas.
