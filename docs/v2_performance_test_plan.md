# v2 Performance Test Plan

This document outlines target performance thresholds for client-server operations.

## Metrics & Targets

- **Dashboard Loading**: Under 300ms from cache.
- **Attendance Synchronization**: Under 500ms for batch changes.
- **Bulk Imports (100+ items)**: Async task offloading to queue with progress indicators.
- **Concurrent Connections**: 10k synthetic users.
- **Server CPU Limit**: Retain usage under 60% during peak login windows.
