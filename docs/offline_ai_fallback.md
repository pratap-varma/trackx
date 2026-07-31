# Offline Deterministic AI Fallback

When a network connection is missing or the student chooses "Offline only" provider mode, TrackX continues functioning locally.

## Fallback Details
- Renders local calculations: days remaining, attendance status, list of assignments.
- Uses templates for study plans and breakdowns.
- Injects a standard status header: *"AI is currently unavailable. TrackX is showing a calculation-based summary instead."*
