# Privacy Impact Assessment (PIA) v2

This document details personal data collection, locations, and deletion controls.

## Personal Data Mapping

- **Student Notes & AI Chats**: Stored in user-specific private Firestore paths. Unrelated notes are never shared with institutions.
- **Location Coordinates**: Used only locally for geofencing suggested check-ins. Coordinates are never uploaded to TrackX or university servers.
- **De-enrollment & Deletion**: Disconnecting an institution deletes OAuth tokens and imported logs, preserving personal logs.
