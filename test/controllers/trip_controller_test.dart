import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mileage_tracker/controllers/trip_controller.dart';
import 'package:mileage_tracker/models/trip_category.dart';
import 'package:mileage_tracker/models/trip_category_summary.dart';
import 'package:mileage_tracker/models/vehicle.dart';
import 'package:mileage_tracker/services/distance_estimator.dart';

const _vehicles = <Vehicle>[
  Vehicle(id: 'vehicle-1', displayName: 'Sedan · ABC123'),
  Vehicle(id: 'vehicle-2', displayName: 'SUV · JKL890'),
];

void main() {
  group('TripController', () {
    test('starts and stops a trip while updating elapsed time', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 60),
        );

        controller.toggleTrip();
        expect(controller.tripActive, isTrue);
        expect(controller.startTime, isNotNull);

        async.elapse(const Duration(seconds: 5));
        expect(controller.elapsed.inSeconds, greaterThanOrEqualTo(5));

        controller.toggleTrip();
        expect(controller.tripActive, isFalse);
        expect(controller.lastCompletedTrip, isNotNull);

        controller.dispose();
      });
    });

    test('summarises history by category', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 60),
        );

        controller.selectCategory(TripCategory.business);
        controller.toggleTrip();
        async.elapse(const Duration(minutes: 30));
        controller.toggleTrip();

        controller.selectCategory(TripCategory.personal);
        controller.toggleTrip();
        async.elapse(const Duration(minutes: 15));
        controller.toggleTrip();

        controller.selectCategory(TripCategory.business);
        controller.toggleTrip();
        async.elapse(const Duration(minutes: 45));
        controller.toggleTrip();

        final summaries = controller.categorySummaries;
        final businessSummary = summaries
            .firstWhere((summary) => summary.category == TripCategory.business);
        final personalSummary = summaries
            .firstWhere((summary) => summary.category == TripCategory.personal);

        expect(businessSummary.tripCount, 2);
        expect(businessSummary.totalDuration, const Duration(minutes: 75));
        expect(
          businessSummary.totalDistanceKm,
          isNotNull,
        );
        expect(
          businessSummary.totalDistanceKm!,
          closeTo(75.0, 0.1),
        );
        expect(
          businessSummary.averageDistanceKm,
          closeTo(37.5, 0.1),
        );

        expect(personalSummary.tripCount, 1);
        expect(personalSummary.totalDuration, const Duration(minutes: 15));
        expect(
          personalSummary.totalDistanceKm,
          closeTo(15.0, 0.1),
        );

        controller.dispose();
      });
    });

    test('records trip history and enforces max history size', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 45),
          maxHistoryItems: 2,
        );

        for (var i = 0; i < 3; i++) {
          controller.toggleTrip();
          async.elapse(const Duration(minutes: 10));
          controller.toggleTrip();
          async.elapse(const Duration(seconds: 1));
        }

        expect(controller.tripHistory, hasLength(2));
        expect(controller.lastCompletedTrip, isNotNull);
        expect(controller.tripHistory.first.duration.inMinutes, 10);
        expect(
          controller.tripHistory.first.distanceKm,
          closeTo(7.5, 0.1),
        );

        controller.dispose();
      });
    });

    test('ignores category and vehicle changes while trip is active', () {
      fakeAsync((async) {
        final controller = TripController(vehicles: _vehicles);

        controller.selectCategory(TripCategory.personal);
        controller.setActiveVehicle('vehicle-2');

        controller.toggleTrip();
        async.elapse(const Duration(seconds: 1));

        controller.selectCategory(TripCategory.business);
        controller.setActiveVehicle('vehicle-1');

        expect(controller.selectedCategory, TripCategory.personal);
        expect(controller.activeVehicleId, 'vehicle-2');

        controller.toggleTrip();
        controller.dispose();
      });
    });

    test('aggregates total duration and distance from history', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 60),
        );

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 30));
        controller.toggleTrip();

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 15));
        controller.toggleTrip();

        expect(controller.tripHistory, hasLength(2));
        expect(controller.totalLoggedDuration, const Duration(minutes: 45));
        expect(
          controller.totalLoggedDistanceKm,
          closeTo(45.0, 0.1),
        );

        controller.dispose();
      });
    });

    test('calculates average speed across history', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 60),
        );

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 20));
        controller.toggleTrip();

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 40));
        controller.toggleTrip();

        expect(controller.totalLoggedDistanceKm, closeTo(60, 0.1));
        expect(controller.totalLoggedAverageSpeedKph, closeTo(60, 0.1));

        controller.dispose();
      });
    });

    test('supports removing and restoring trips', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 60),
        );

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 15));
        controller.toggleTrip();

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 30));
        controller.toggleTrip();

        final removed = controller.removeTripAt(0);
        expect(removed, isNotNull);
        expect(controller.tripHistory, hasLength(1));
        expect(controller.lastCompletedTrip, isNotNull);
        expect(
          controller.lastCompletedTrip!.startTime,
          controller.tripHistory.first.startTime,
        );

        controller.restoreTrip(removed!, index: 0);

        expect(controller.tripHistory, hasLength(2));
        expect(
          controller.tripHistory.first.startTime,
          removed.startTime,
        );
        expect(controller.lastCompletedTrip, isNotNull);
        expect(
          controller.lastCompletedTrip!.startTime,
          controller.tripHistory.first.startTime,
        );

        controller.dispose();
      });
    });

    test('clears trip history when requested', () {
      fakeAsync((async) {
        final controller = TripController(
          vehicles: _vehicles,
          distanceEstimator: const DistanceEstimator(fallbackSpeedKph: 60),
        );

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 10));
        controller.toggleTrip();

        controller.toggleTrip();
        async.elapse(const Duration(minutes: 5));
        controller.toggleTrip();

        expect(controller.tripHistory, hasLength(2));

        controller.clearHistory();

        expect(controller.tripHistory, isEmpty);
        expect(controller.lastCompletedTrip, isNull);

        controller.dispose();
      });
    });

    test('does not start trips when there are no vehicles', () {
      fakeAsync((async) {
        final controller = TripController(vehicles: const []);

        controller.toggleTrip();

        expect(controller.tripActive, isFalse);
        expect(controller.startTime, isNull);
        expect(controller.currentVehicle, isNull);

        controller.dispose();
      });
    });
  });
}
