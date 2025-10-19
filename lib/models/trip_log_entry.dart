import 'geo_point.dart';
import 'trip.dart';
import 'trip_category.dart';
import 'trip_location_sample.dart';

/// Lightweight view model representing a recently captured trip.
class TripLogEntry {
  const TripLogEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.vehicleName,
    required this.category,
    required this.duration,
    required this.startPosition,
    required this.endPosition,
    required this.startOdometer,
    required this.endOdometer,
    this.distanceKm,
    this.averageSpeedKph,
    this.startAddress,
    this.endAddress,
    this.route = const <TripLocationSample>[],
    this.notes,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String vehicleName;
  final TripCategory category;
  final Duration duration;
  final GeoPoint startPosition;
  final GeoPoint endPosition;
  final double startOdometer;
  final double endOdometer;
  final double? distanceKm;
  final double? averageSpeedKph;
  final String? startAddress;
  final String? endAddress;
  final List<TripLocationSample> route;
  final String? notes;

  double get odometerDelta => endOdometer - startOdometer;

  factory TripLogEntry.fromTrip(
    Trip trip, {
    List<TripLocationSample> route = const <TripLocationSample>[],
    double? distanceKm,
    double? averageSpeedKph,
  }) {
    return TripLogEntry(
      id: trip.id,
      startTime: trip.startTime,
      endTime: trip.endTime,
      vehicleName: trip.vehicle?.displayName ?? trip.vehicleId,
      category: trip.category,
      duration: trip.duration,
      startPosition: trip.startPosition,
      endPosition: trip.endPosition,
      startOdometer: trip.startOdometer,
      endOdometer: trip.endOdometer,
      distanceKm: distanceKm,
      averageSpeedKph: averageSpeedKph,
      startAddress: trip.startAddress,
      endAddress: trip.endAddress,
      route: route,
      notes: trip.notes,
    );
  }
}
