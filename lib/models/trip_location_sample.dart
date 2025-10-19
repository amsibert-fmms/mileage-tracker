import 'geo_point.dart';

/// Represents a recorded GPS point captured during a trip.
class TripLocationSample {
  const TripLocationSample({
    required this.position,
    required this.recordedAt,
    this.sequence,
  });

  final GeoPoint position;
  final DateTime recordedAt;
  final int? sequence;

  TripLocationSample copyWith({
    GeoPoint? position,
    DateTime? recordedAt,
    int? sequence,
  }) {
    return TripLocationSample(
      position: position ?? this.position,
      recordedAt: recordedAt ?? this.recordedAt,
      sequence: sequence ?? this.sequence,
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position.toJson(),
        'recordedAt': recordedAt.toIso8601String(),
        'sequence': sequence,
      };

  factory TripLocationSample.fromJson(Map<String, dynamic> json) {
    return TripLocationSample(
      position: GeoPoint.fromJson(json['position'] as Map<String, dynamic>),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      sequence: json['sequence'] as int?,
    );
  }
}
