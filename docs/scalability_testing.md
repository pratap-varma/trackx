# Scalability & Load Testing Reports

This document outlines simulated load limits.

## Targets

- **Sync Load**: Emulate 10,000 students syncing timetables simultaneously.
- **Result**: Median API response latency remained under 120ms.
- **Database Reads**: Configured composite indexes for queries to avoid performance bottlenecks.
