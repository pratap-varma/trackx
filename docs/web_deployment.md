# Web Dashboard Deployment Guide

This guide details how to build and host the TrackX Web Dashboard.

## Compilation

Build the web application package using the following command:

```bash
flutter build web --release --web-renderer canvaskit
```

## Hosting Configuration

### Firebase Hosting Setup

Deploy the built files using Firebase CLI:

```bash
firebase init hosting
# Set public directory to: build/web
firebase deploy --only hosting
```

### Content Security Policy (CSP)

Ensure headers restrict source connections:
- `script-src 'self' https://apis.google.com`
- `connect-src 'self' https://*.firestore.googleapis.com`
