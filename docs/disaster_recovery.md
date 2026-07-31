# Disaster Recovery Plan

This document details database recovery, backups, and outages handling.

## Backup Standards

- **Firestore**: Automated daily exports stored in multi-region backup storage.
- **RPO (Recovery Point Objective)**: Max 24 hours.
- **RTO (Recovery Time Objective)**: Max 4 hours.

## Emergency Rollbacks

If a bad migration corrupts active documents:
1. Revert Cloud Functions version to the previous stable release tag.
2. Execute the restore script to replace data from the latest backup.
