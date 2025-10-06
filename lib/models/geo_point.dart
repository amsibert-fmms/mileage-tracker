/// Represents a geographic coordinate in decimal degrees.
///
/// The [latitude] must be between -90 and 90 degrees, and the [longitude]
/// between -180 and 180 degrees. Values outside of this range will throw an
/// [ArgumentError] to catch issues early in development.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude})
      : assert(latitude >= -90 && latitude <= 90,
            'Latitude must be between -90 and 90.'),
        assert(longitude >= -180 && longitude <= 180,
            'Longitude must be between -180 and 180.');

  final double latitude;
  final double longitude;

  GeoPoint copyWith({double? latitude, double? longitude}) {
    return GeoPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'GeoPoint(lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) {
    return other is GeoPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
