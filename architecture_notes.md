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

## Key Decisions
- Keep controllers lightweight; consider `Riverpod` or `Provider` for state management once complexity grows.
- SQLite chosen over Hive for relational querying of trips and vehicles.
- All optional sync operations occur after local persistence to preserve offline reliability.

