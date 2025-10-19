# Mileage tracker

## Overview
Mileage Tracker is a Flutter application designed to capture business mileage with as little manual input as possible. Drivers tap once to start a trip, tap once to stop, and the app handles timestamps, location lookups, and distance calculations automatically. All records stay in the driver's control and can be stored locally or synchronised to a private Google Sheet for backup.

## Key capabilities
- One-tap start and stop controls that log timestamps and GPS coordinates in real time.
- Automatic calculation of trip duration, estimated distance, and average speed once a trip ends.
- Quick vehicle selection keeps the last used vehicle preselected for faster logging.
- Trip categorisation (Business, Personal, Commute, Other) with room for additional notes or tags.
- Works offline-first: trips persist locally before any optional cloud sync occurs.

## Data ownership and storage
| Storage option | Description |
| --- | --- |
| Local SQLite database | Primary persistence layer that captures trips, vehicles, and saved locations on device. |
| CSV export | Generates shareable CSV files suitable for accounting tools or spreadsheets. |
| Google Sheets sync (optional) | Uses the driver's Google account via OAuth2 to mirror the local dataset into a private spreadsheet for routine backups. |

Backups can be scheduled externally (e.g., Google Drive automations, desktop sync clients) using either the CSV exports or the linked Google Sheet.

## User experience principles
- **Minimal interaction:** default selections and on-demand prompts reduce typing or repeated inputs.
- **Privacy first:** location access occurs only during active trips; all data stays local until the user opts into sync.
- **Resilience:** GPS reads queue when the device is offline and complete once connectivity returns.
- **Transparency:** every trip stores human-readable start and end locations via reverse geocoding.

## Architecture snapshot
| Layer | Responsibilities | Key packages |
| --- | --- | --- |
| Presentation (`lib/screens`, `lib/widgets`) | Material 3 UI for trip controls, history, vehicles, and settings. | `flutter`, `go_router` (planned) |
| Domain (`lib/models`, `lib/controllers`) | Trip, vehicle, and tagging models plus controllers that orchestrate logging workflows. | Plain Dart, `riverpod`/`provider` (evaluated) |
| Data (`lib/services`) | SQLite persistence, location services, and export/sync connectors. | `sqflite`, `path_provider`, `geolocator`, `geocoding`, Google Sheets/CSV helpers |

Refer to [`architecture_notes.md`](architecture_notes.md) for deeper design details.

## Release target
The initial distribution format for Mileage Tracker is an Android build published on Google Play. Additional platforms will be
considered once the Android release is stable and telemetry confirms feature completeness.

## Development quick start
1. Install [Flutter 3.35.5](https://docs.flutter.dev/get-started/install) and run `flutter doctor`.
2. Fetch packages:
   ```sh
   flutter pub get
   ```
3. Launch the app on your preferred platform:
   ```sh
   flutter run
   ```
4. For web testing, enable web support and run `flutter run -d chrome`.

## Additional documentation
- [`architecture_notes.md`](architecture_notes.md) – data flow, module structure, and entities.
- [`MVP Checklist.md`](MVP%20Checklist.md) – current implementation to-do list.
- [`DEVELOPMENT_SETUP.md`](DEVELOPMENT_SETUP.md) – environment setup details.

## Roadmap highlights
- Background auto-trip mode triggered by motion or Bluetooth beacons.
- Enhanced analytics and dashboards for mileage summaries and tax estimates.
- Multi-device sync options beyond Google Sheets backups.
- Map-based route visualisations for trip review.
