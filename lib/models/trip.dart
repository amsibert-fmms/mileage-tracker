import 'dart:math' as math;

import 'geo_point.dart';
import 'saved_location.dart';
import 'vehicle.dart';

/// Core domain entity capturing a mileage trip.
class Trip {
  static const Object _unset = Object();

  const Trip({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.startPosition,
    required this.endPosition,
    required this.startOdometer,
    required this.endOdometer,
    required this.vehicleId,
    this.vehicle,
    this.startLocationId,
    this.endLocationId,
    this.startLocation,
    this.endLocation,
    this.notes,
    this.tags = const <String>[],
  }) : assert(endTime.isAfter(startTime), 'End time must be after start time.');

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final GeoPoint startPosition;
  final GeoPoint endPosition;
  final double startOdometer;
  final double endOdometer;
  final String vehicleId;

  /// Optional vehicle snapshot at the time of the trip.
  final Vehicle? vehicle;

  /// Link to saved locations for quick reuse in the UI.
  final String? startLocationId;
  final String? endLocationId;

  /// Optional denormalised saved location references.
  final SavedLocation? startLocation;
  final SavedLocation? endLocation;

  final String? notes;

  /// Free form tags (e.g. "Personal", "Client A") until tagging entity exists.
  final List<String> tags;

  Duration get duration => endTime.difference(startTime);

  double get distance =>
      math.max(0.0, endOdometer - startOdometer);

  Trip copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    GeoPoint? startPosition,
    GeoPoint? endPosition,
    double? startOdometer,
    double? endOdometer,
    String? vehicleId,
    Object? vehicle = _unset,
    Object? startLocationId = _unset,
    Object? endLocationId = _unset,
    Object? startLocation = _unset,
    Object? endLocation = _unset,
    Object? notes = _unset,
    List<String>? tags,
  }) {
    return Trip(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      startOdometer: startOdometer ?? this.startOdometer,
      endOdometer: endOdometer ?? this.endOdometer,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: identical(vehicle, _unset) ? this.vehicle : vehicle as Vehicle?,
      startLocationId: identical(startLocationId, _unset)
          ? this.startLocationId
          : startLocationId as String?,
      endLocationId: identical(endLocationId, _unset)
          ? this.endLocationId
          : endLocationId as String?,
      startLocation: identical(startLocation, _unset)
          ? this.startLocation
          : startLocation as SavedLocation?,
      endLocation: identical(endLocation, _unset)
          ? this.endLocation
          : endLocation as SavedLocation?,
      notes:
          identical(notes, _unset) ? this.notes : notes as String?,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'startPosition': startPosition.toJson(),
        'endPosition': endPosition.toJson(),
        'startOdometer': startOdometer,
        'endOdometer': endOdometer,
        'vehicleId': vehicleId,
        'vehicle': vehicle?.toJson(),
        'startLocationId': startLocationId,
        'endLocationId': endLocationId,
        'notes': notes,
        'tags': tags,
        'startLocation': startLocation?.toJson(),
        'endLocation': endLocation?.toJson(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      startPosition:
          GeoPoint.fromJson(json['startPosition'] as Map<String, dynamic>),
      endPosition: GeoPoint.fromJson(json['endPosition'] as Map<String, dynamic>),
      startOdometer: (json['startOdometer'] as num).toDouble(),
      endOdometer: (json['endOdometer'] as num).toDouble(),
      vehicleId: json['vehicleId'] as String,
      vehicle: json['vehicle'] == null
          ? null
          : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      startLocationId: json['startLocationId'] as String?,
      endLocationId: json['endLocationId'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
      startLocation: json['startLocation'] == null
          ? null
          : SavedLocation.fromJson(
              json['startLocation'] as Map<String, dynamic>),
      endLocation: json['endLocation'] == null
          ? null
          : SavedLocation.fromJson(
              json['endLocation'] as Map<String, dynamic>),
    );
  }

  bool get hasSavedLocations =>
      startLocationId != null || endLocationId != null;

  bool get hasVehicleSnapshot => vehicle != null;

  @override
  String toString() =>
      'Trip($startTime -> $endTime, vehicle: $vehicleId, distance: $distance)';

  @override
  bool operator ==(Object other) {
    return other is Trip &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.startPosition == startPosition &&
        other.endPosition == endPosition &&
        other.startOdometer == startOdometer &&
        other.endOdometer == endOdometer &&
        other.vehicleId == vehicleId &&
        other.startLocationId == startLocationId &&
        other.endLocationId == endLocationId &&
        other.startLocation == startLocation &&
        other.endLocation == endLocation &&
        other.notes == notes &&
        _listEquals(other.tags, tags);
  }

  @override
  int get hashCode => Object.hash(
      id,
      startTime,
      endTime,
      startPosition,
      endPosition,
      startOdometer,
      endOdometer,
      vehicleId,
      startLocationId,
      endLocationId,
      startLocation,
      endLocation,
      notes,
      Object.hashAll(tags));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
