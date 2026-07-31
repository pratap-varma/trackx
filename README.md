# TrackX

> **Track Smarter. Plan Better.**

TrackX is a modern, offline-first student productivity and attendance tracking application built with Flutter, Riverpod, and GoRouter. It features an Apple VisionOS-inspired frosted glass theme.

---

## Key Features

- **Attendance Tracking**: Subject-wise and slot-wise daily tracking, safe-to-miss calculators, and recovery statistics.
- **Weekly Timetable**: Slot scheduling with automated conflict validation.
- **Productivity Dashboard**: CGPA/SGPA grade simulations, checklists, and academic calendars.
- **Offline-First Synchronization**: Write transactions offline; automatically syncs with Firestore when internet returns.
- **AI Academic Advisor**: Intelligent context-aware helper proposing tips while respecting custom privacy preferences.
- **Home-Screen Widgets**: Shared data summaries for small, medium, and large layouts.
- **Location Geofences**: Voluntary reminders to confirm attendance when inside classroom ranges.

---

## Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (iOS, Android, Web)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Database**: [Hive](https://pub.dev/packages/hive) & [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **Cloud Backend**: Firebase (Auth, Firestore, Cloud Storage)
- **Design Pattern**: Feature-First architecture separating concern layers.

---

## Documentation

For guides, setup instructions, and checklists:
- [Firebase Setup Guide](docs/firebase_setup.md)
- [Developer Setup Guide](docs/development_setup.md)
- [Installation Instructions](docs/installation.md)
- [Architecture & Data Flow](docs/architecture.md)
- [Release Readiness Checklist](docs/release_checklist.md)
- [Changelog](CHANGELOG.md)

---

## License

This project is licensed under the [MIT License](LICENSE).
