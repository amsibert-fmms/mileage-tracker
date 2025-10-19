import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

/// Provides distance and speed calculations using GPS data with fallbacks to a
/// configurable estimated speed.
class DistanceEstimator {
  const DistanceEstimator({this.fallbackSpeedKph = 45});

  /// Default average speed (in km/h) used when insufficient telemetry is
  /// available to infer distance.
  final double fallbackSpeedKph;

  /// Estimates the travelled distance in kilometres using the configured
  /// fallback speed. Used when we cannot compute an accurate reading.
  double estimateDistanceKm(Duration duration) {
    if (duration.inSeconds <= 0) {
      return 0;
    }
    final hours = duration.inSeconds / 3600;
    return fallbackSpeedKph * hours;
  }

  /// Computes the total distance of the supplied [route] in kilometres using the
  /// Haversine distance between samples. Falls back to [estimateDistanceKm] when
  /// there are too few samples or telemetry reports zero distance.
  double distanceFromRoute(Duration duration, List<GeoPoint> route) {
    if (route.length < 2) {
      return estimateDistanceKm(duration);
    }
    var metres = 0.0;
    for (var i = 1; i < route.length; i++) {
      final previous = route[i - 1];
      final current = route[i];
      metres += Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        current.latitude,
        current.longitude,
      );
    }
    final km = metres / 1000;
    if (km <= 0) {
      return estimateDistanceKm(duration);
    }
    return km;
  }

  /// Returns the straight line distance between two [GeoPoint]s in kilometres.
  double straightLineDistance(GeoPoint a, GeoPoint b) {
    final distance = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return distance / 1000;
  }

  /// Derives the average speed (in km/h) from a distance over the supplied
  /// [duration]. Returns 0 if the duration is zero to avoid division errors.
  double averageSpeedKmPerHour({
    required double distanceKm,
    required Duration duration,
  }) {
    if (duration.inSeconds <= 0) {
      return 0;
    }
    final hours = duration.inSeconds / 3600;
    return distanceKm / hours;
  }
}
