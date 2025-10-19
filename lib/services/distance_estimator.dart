/// Provides lightweight distance and speed calculations until GPS data is wired
/// into the trip pipeline.
class DistanceEstimator {
  const DistanceEstimator({this.fallbackSpeedKph = 45});

  /// Default average speed (in km/h) used to approximate travelled distance.
  final double fallbackSpeedKph;

  /// Estimates the travelled distance in kilometres using the configured
  /// fallback speed. Once GPS integration lands, this method can switch to an
  /// actual geospatial distance calculation.
  double estimateDistanceKm(Duration duration) {
    if (duration.inSeconds <= 0) {
      return 0;
    }
    final hours = duration.inSeconds / 3600;
    return fallbackSpeedKph * hours;
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
