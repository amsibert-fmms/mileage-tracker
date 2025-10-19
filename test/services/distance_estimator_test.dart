import 'package:flutter_test/flutter_test.dart';

import 'package:mileage_tracker/services/distance_estimator.dart';

void main() {
  group('DistanceEstimator', () {
    test('returns zero distance for non-positive durations', () {
      const estimator = DistanceEstimator(fallbackSpeedKph: 50);

      expect(estimator.estimateDistanceKm(Duration.zero), 0);
      expect(estimator.estimateDistanceKm(const Duration(seconds: -1)), 0);
    });

    test('calculates distance using fallback speed', () {
      const estimator = DistanceEstimator(fallbackSpeedKph: 60);

      final result = estimator.estimateDistanceKm(const Duration(minutes: 30));

      expect(result, closeTo(30.0, 0.001));
    });

    test('computes average speed safely', () {
      const estimator = DistanceEstimator();

      expect(
        estimator.averageSpeedKmPerHour(distanceKm: 10, duration: Duration.zero),
        0,
      );

      final average = estimator.averageSpeedKmPerHour(
        distanceKm: 45,
        duration: const Duration(minutes: 30),
      );

      expect(average, closeTo(90.0, 0.001));
    });
  });
}
