# Role-Based Access Control (RBAC) Design

This document details roles, permissions, and claims management.

## Permissions Directory

- `Student`: Read timetable, read official attendance.
- `Faculty`: Read assigned sections roster, submit class logs.
- `Institution Admin`: Manage course offerings, verify members.

## Security Practices

- **Token Refresh**: Token sessions must be revoked immediately if a user's role shifts.
- **Custom Claims Limits**: Store only stable role mappings inside authentication claims.
