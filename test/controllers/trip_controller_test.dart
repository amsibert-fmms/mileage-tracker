import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mileage_tracker/controllers/trip_controller.dart';
import 'package:mileage_tracker/models/trip_category.dart';
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
