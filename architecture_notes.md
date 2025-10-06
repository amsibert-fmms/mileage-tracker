# Architecture Notes

## High-Level Overview
- **Presentation Layer** (`lib/screens`, `lib/widgets`)
  - Flutter Material 3 UI components for primary screens: Home (trip controls), History, Vehicles, Settings.
  - Navigation via `GoRouter` or Flutter's `Navigator 2.0` once routes expand.
- **Domain Layer** (`lib/models`, `lib/controllers`)
  - Core entities: `Trip`, `Vehicle`, `TripTag` enum.
  - Service interfaces that encapsulate location, storage, and export behaviors.
- **Data Layer** (`lib/services`)
  - SQLite persistence via `sqflite` and `path_provider`.
  - Location services via `geolocator` and `geocoding`.
  - CSV export helper leveraging `csv` package.

## Folder Structure Sketch
```
lib/
  main.dart
  app.dart                // top-level MaterialApp + route configuration
  screens/
    home_screen.dart      // start/stop controls, live status
    history_screen.dart   // list of trips with filters
    vehicle_screen.dart   // manage vehicles
    settings_screen.dart  // exports, integrations
  widgets/
    primary_button.dart
    trip_card.dart
  models/
    trip.dart
    vehicle.dart
    trip_tag.dart
  services/
    trip_repository.dart  // SQLite CRUD
    location_service.dart // GPS + reverse geocoding
    export_service.dart   // CSV generation
  controllers/
    trip_controller.dart  // orchestrates trip lifecycle
    vehicle_controller.dart
```

## Data Flow
1. UI triggers actions (e.g., `TripController.startTrip()`).
2. Controller requests GPS fix from `LocationService`.
3. Once trip ends, controller computes derived metrics and persists via `TripRepository`.
4. History screen observes repository stream to refresh list view.
5. Export actions delegate to `ExportService` to build CSV files.

## Data Model
- **Trip**
  - Represents a single recorded journey with a `startTime`, `endTime`, and geospatial coordinates captured as `GeoPoint` snapshots for both the beginning and end of the trip.
  - Stores odometer readings (`startOdometer`, `endOdometer`) to derive distance, as well as the `vehicleId` that links the trip to a specific vehicle.
  - Optionally embeds denormalised `Vehicle` and `SavedLocation` snapshots to make presenting historic data in the UI resilient to later edits.
  - Supports free-form metadata via `notes` and an array of string `tags` to enable categorisation even before a richer tagging system exists.
- **Vehicle**
  - Defines the set of cars the user can associate with trips, including display metadata (`displayName`, `make`, `model`, `year`, `licensePlate`).
  - Carries an optional `defaultOdometer` for seeding future trip entries and an `isActive` flag so the app can surface the most commonly used vehicle by default.
- **SavedLocation**
  - Allows users to bookmark frequently used places, combining a human readable `label`, geographic `position`, optional `addressLine`, and `notes` for context.
  - Trips reference saved locations through both `startLocationId` / `endLocationId` foreign keys and cached `SavedLocation` objects for offline friendliness.
- **GeoPoint**
  - Lightweight value object that constrains latitude and longitude to valid ranges and serialises cleanly for persistence.
  - Reused by both trips and saved locations to represent map coordinates without tying the data model to a specific geolocation provider.

## Key Decisions
- Keep controllers lightweight; consider `Riverpod` or `Provider` for state management once complexity grows.
- SQLite chosen over Hive for relational querying of trips and vehicles.
- All optional sync operations occur after local persistence to preserve offline reliability.

