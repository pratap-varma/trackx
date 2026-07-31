# Data Retention Policy

This document details data lifecycle and automatic purging.

## Lifespans Directory

- **Audit Logs**: Retain for 12 months, then automatically archive.
- **Deleted User Profiles**: Purge Firestore documents 30 days after deletion request.
- **Temporary Uploads**: Delete temporary timetable uploads 24 hours after processing completes.
