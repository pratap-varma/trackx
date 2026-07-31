# Release Checklist

Use this checklist to verify production release readiness before tagging a version:

- [ ] **Static Analysis**: Verify `flutter analyze` returns zero issues.
- [ ] **Tests Pass**: Run `flutter test` and check that all 27 unit and widget tests pass.
- [ ] **Version Synchronization**: Verify `pubspec.yaml` contains correct semantic versioning (e.g. `1.0.0`).
- [ ] **No Committed Secrets**: Review staged files and ensure no private API keys or Firebase service accounts are committed.
- [ ] **Documentation**: Ensure `CHANGELOG.md` is updated and guides under `docs/` are in place.
- [ ] **Visual Design**: Verify light/dark theme contrast and responsiveness across screens.
- [ ] **Release Build**: Generate universal APK using `flutter build apk --release` and verify size and SHA-256 checksums.
