import 'trip_category.dart';

/// Lightweight view model representing a recently captured trip.
class TripLogEntry {
  const TripLogEntry({
    required this.startTime,
    required this.endTime,
    required this.vehicleName,
    required this.category,
    required this.duration,
    this.distanceKm,
    this.averageSpeedKph,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String vehicleName;
  final TripCategory category;
  final Duration duration;
  final double? distanceKm;
  final double? averageSpeedKph;
}
