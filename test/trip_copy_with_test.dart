import 'package:flutter_test/flutter_test.dart';
import 'package:mileage_tracker/models/models.dart';

void main() {
  group('Trip.copyWith', () {
    final baseTrip = Trip(
      id: 'trip-1',
      startTime: DateTime(2024, 1, 1, 8),
      endTime: DateTime(2024, 1, 1, 9),
      startPosition: const GeoPoint(latitude: 51.5, longitude: -0.1),
      endPosition: const GeoPoint(latitude: 51.6, longitude: -0.12),
      startOdometer: 1000,
      endOdometer: 1015,
      vehicleId: 'vehicle-1',
      vehicle: const Vehicle(id: 'vehicle-1', displayName: 'Sedan'),
      startLocationId: 'home',
      endLocationId: 'office',
      startLocation: const SavedLocation(
        id: 'home',
        label: 'Home',
        position: GeoPoint(latitude: 51.5, longitude: -0.1),
      ),
      endLocation: const SavedLocation(
        id: 'office',
        label: 'Office',
        position: GeoPoint(latitude: 51.6, longitude: -0.12),
      ),
      notes: 'Morning commute',
      tags: const <String>['Business'],
    );

    test('allows clearing optional fields by passing null', () {
      final updated = baseTrip.copyWith(
        vehicle: null,
        startLocationId: null,
        endLocationId: null,
        startLocation: null,
        endLocation: null,
        notes: null,
      );

      expect(updated.vehicle, isNull);
      expect(updated.startLocationId, isNull);
      expect(updated.endLocationId, isNull);
      expect(updated.startLocation, isNull);
      expect(updated.endLocation, isNull);
      expect(updated.notes, isNull);

      // Unchanged properties should remain untouched.
      expect(updated.id, baseTrip.id);
      expect(updated.tags, baseTrip.tags);
      expect(updated.vehicleId, baseTrip.vehicleId);
    });

    test('still updates provided non-null values', () {
      final newVehicle = const Vehicle(id: 'vehicle-2', displayName: 'EV');
      final updated = baseTrip.copyWith(
        vehicleId: 'vehicle-2',
        vehicle: newVehicle,
        notes: 'Client visit',
        tags: const <String>['Client A'],
      );

      expect(updated.vehicleId, 'vehicle-2');
      expect(updated.vehicle, newVehicle);
      expect(updated.notes, 'Client visit');
      expect(updated.tags, const <String>['Client A']);
    });
  });
}
