# Data Export JSON Schema Specification

This document details the standard schema versioning rules for user-initiated data portability.

## JSON Fields Definition

- `version`: Version tag (e.g. `2.1.0`).
- `userProfile`: User metadata excluding credentials.
- `semesters`: Array of semester schedules, subjects, and attendance values.
- `studyTimerSessions`: Focused study history logs.
- `recommendationPreferences`: Optional toggle preferences.
