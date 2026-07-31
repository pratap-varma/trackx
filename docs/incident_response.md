# Incident Response Protocol

This document details severity levels, response teams, and actions sequence.

## Severity Levels

- **SEV-1 (Critical)**: Active data leakage, server outage.
- **SEV-2 (High)**: Sync repeated failures, missing notifications.
- **SEV-3 (Medium)**: Cosmetic UI bugs.

## Sequence of Actions

1. **Containment**: Revoke leaked API credentials or lock down database permissions.
2. **Mitigation**: Deploy the patch.
3. **Disclosure**: Inform affected institutional admins within 72 hours of verification.
