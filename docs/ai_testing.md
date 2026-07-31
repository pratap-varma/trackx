# AI Assistant Testing

TrackX utilizes robust unit and mock tests to guarantee reliability.

## Test Areas
- Context consent filters (`AiContextBuilder`).
- Action validations & conflict warnings (`AiActionValidator`).
- Offline templates output verification (`OfflineFallbackProvider`).

Run tests using:
```bash
flutter test test/stage17_ai_assistant_test.dart
```
