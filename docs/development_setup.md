# Developer Setup Guide

Follow these steps to set up the TrackX development workspace.

## Prerequisites
- Flutter SDK (Stable Channel, v3.22.x or later)
- Dart SDK
- Java Development Kit (JDK 17)
- Android Studio / VS Code

## Setup Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/trackx.git
   cd trackx
   ```

2. **Install Packages**:
   ```bash
   flutter pub get
   ```

3. **Configure Local Firebase**:
   Configure FlutterFire CLI options or add native configuration files (`google-services.json` and `GoogleService-Info.plist`).

4. **Run Unit Tests**:
   ```bash
   flutter test
   ```

5. **Run the Application**:
   ```bash
   flutter run
   ```
