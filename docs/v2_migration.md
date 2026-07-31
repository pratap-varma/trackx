# v2 Data Migration Strategy

This document details migration checkpoints for existing profiles.

## Checkpoint Sequencing

1. **Schema Check**: Read current version metadata from Hive storage.
2. **Batch Mapping**: Map old courses array to the new CourseOffering model structure.
3. **Rollback Safety**: On error, pause migration execution and restore the local backup.
