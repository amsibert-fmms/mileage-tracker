import 'trip_category.dart';

/// Aggregated metrics for trips belonging to a specific [category].
class TripCategorySummary {
  const TripCategorySummary({
    required this.category,
    required this.tripCount,
    required this.totalDuration,
    this.totalDistanceKm,
  });

  final TripCategory category;
  final int tripCount;
  final Duration totalDuration;
  final double? totalDistanceKm;

  /// Average distance travelled per trip for this category, if known.
  double? get averageDistanceKm {
    if (tripCount == 0 || totalDistanceKm == null) {
      return null;
    }
    return totalDistanceKm! / tripCount;
  }
}
