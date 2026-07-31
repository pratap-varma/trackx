# Wear OS & Apple Watch Companion

TrackX companion companion support.

## Supported Features

- View today's timetable summary.
- View next class countdown.
- Confirm pending attendance notifications.

## Data Sync Protocol

- Mobile device communicates via platform channels (`WearableDataClient` for Wear OS, `WCSession` for watchOS).
- Sync messages are sent as key-value maps. Keep payloads small: do not send notes or attachments.
- When offline, display cached data with a "Phone Disconnected" label.
