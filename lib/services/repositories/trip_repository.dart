import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/geo_point.dart';
import '../../models/trip.dart';
import '../../models/trip_category.dart';
import '../../models/trip_location_sample.dart';
import '../../models/vehicle.dart';
import '../database/mileage_database.dart';
import '../database/persistence_queue.dart';

class PersistedTrip {
  const PersistedTrip({
    required this.trip,
    this.route = const <TripLocationSample>[],
    this.distanceKm,
    this.averageSpeedKph,
  });

  final Trip trip;
  final List<TripLocationSample> route;
  final double? distanceKm;
  final double? averageSpeedKph;
}

class TripRepository {
  TripRepository({
    MileageDatabase? database,
    PersistenceQueue? queue,
    Uuid? uuid,
  })  : _database = database ?? MileageDatabase.instance,
        _queue = queue ?? PersistenceQueue(),
        _uuid = uuid ?? const Uuid();

  final MileageDatabase _database;
  final PersistenceQueue _queue;
  final Uuid _uuid;

  final StreamController<List<PersistedTrip>> _recentTripsController =
      StreamController<List<PersistedTrip>>.broadcast();
  int _watchLimit = 20;

  Stream<List<PersistedTrip>> watchRecentTrips({int limit = 20}) {
    _watchLimit = limit;
    unawaited(_emitRecent());
    return _recentTripsController.stream;
  }

  Future<List<PersistedTrip>> fetchTrips({int limit = 50, int offset = 0}) async {
    final db = await _database.database;
    final rows = await db.query(
      'trips',
      where: 'deleted = 0',
      orderBy: 'end_time DESC',
      limit: limit,
      offset: offset,
    );
    return _mapTrips(db, rows);
  }

  Future<PersistedTrip> createTrip({
    required Trip trip,
    required List<TripLocationSample> route,
    double? distanceKm,
    double? averageSpeedKph,
  }) {
    return _queue.enqueue(() async {
      final db = await _database.database;
      final record = trip.copyWith(id: trip.id.isEmpty ? _uuid.v4() : trip.id);
      await db.insert(
        'trips',
        _tripToMap(
          record,
          distanceKm: distanceKm,
          averageSpeedKph: averageSpeedKph,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _replaceSamples(db, record.id, route);
      final persistedRoute = await _fetchSamples(db, record.id);
      final persisted = PersistedTrip(
        trip: record,
        route: persistedRoute,
        distanceKm: distanceKm,
        averageSpeedKph: averageSpeedKph,
      );
      await _emitRecent();
      return persisted;
    });
  }

  Future<PersistedTrip?> getTrip(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'trips',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final trip = _mapTrip(rows.single);
    final samples = await _fetchSamples(db, id);
    final stats = _extractStats(rows.single);
    return PersistedTrip(
      trip: trip,
      route: samples,
      distanceKm: stats.$1,
      averageSpeedKph: stats.$2,
    );
  }

  Future<PersistedTrip?> deleteTrip(String id) {
    return _queue.enqueue(() async {
      final db = await _database.database;
      final rows = await db.query(
        'trips',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      final trip = _mapTrip(rows.single);
      final stats = _extractStats(rows.single);
      final samples = await _fetchSamples(db, id);
      await db.update(
        'trips',
        {'deleted': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      await _emitRecent();
      return PersistedTrip(
        trip: trip,
        route: samples,
        distanceKm: stats.$1,
        averageSpeedKph: stats.$2,
      );
    });
  }

  Future<void> restoreTrip(PersistedTrip persisted) {
    return _queue.enqueue(() async {
      final db = await _database.database;
      await db.insert(
        'trips',
        _tripToMap(
          persisted.trip,
          distanceKm: persisted.distanceKm,
          averageSpeedKph: persisted.averageSpeedKph,
          deleted: 0,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _replaceSamples(db, persisted.trip.id, persisted.route);
      await _emitRecent();
    });
  }

  Future<void> clearHistory() {
    return _queue.enqueue(() async {
      final db = await _database.database;
      await db.update('trips', {'deleted': 1});
      await _emitRecent();
    });
  }

  Future<void> purgeDeleted() {
    return _queue.enqueue(() async {
      final db = await _database.database;
      await db.delete('trips', where: 'deleted = 1');
    });
  }

  Future<void> _emitRecent() async {
    final db = await _database.database;
    final rows = await db.query(
      'trips',
      where: 'deleted = 0',
      orderBy: 'end_time DESC',
      limit: _watchLimit,
    );
    final trips = await _mapTrips(db, rows);
    if (!_recentTripsController.isClosed) {
      _recentTripsController.add(trips);
    }
  }

  Map<String, dynamic> _tripToMap(
    Trip trip, {
    double? distanceKm,
    double? averageSpeedKph,
    int deleted = 0,
  }) {
    return {
      'id': trip.id,
      'start_time': trip.startTime.toIso8601String(),
      'end_time': trip.endTime.toIso8601String(),
      'start_lat': trip.startPosition.latitude,
      'start_lng': trip.startPosition.longitude,
      'end_lat': trip.endPosition.latitude,
      'end_lng': trip.endPosition.longitude,
      'start_odometer': trip.startOdometer,
      'end_odometer': trip.endOdometer,
      'vehicle_id': trip.vehicleId,
      'vehicle_name': trip.vehicle?.displayName ?? trip.vehicleId,
      'category': trip.category.name,
      'start_address': trip.startAddress,
      'end_address': trip.endAddress,
      'notes': trip.notes,
      'tags': jsonEncode(trip.tags),
      'distance_km': distanceKm,
      'average_speed_kph': averageSpeedKph,
      'created_at': DateTime.now().toIso8601String(),
      'deleted': deleted,
    };
  }

  Future<void> _replaceSamples(
    Database db,
    String tripId,
    List<TripLocationSample> samples,
  ) async {
    final batch = db.batch();
    batch.delete('trip_location_samples', where: 'trip_id = ?', whereArgs: [tripId]);
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      batch.insert(
        'trip_location_samples',
        {
          'trip_id': tripId,
          'sample_index': i,
          'latitude': sample.position.latitude,
          'longitude': sample.position.longitude,
          'recorded_at': sample.recordedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<PersistedTrip>> _mapTrips(Database db, List<Map<String, Object?>> rows) async {
    final trips = <PersistedTrip>[];
    for (final row in rows) {
      final trip = _mapTrip(row);
      final stats = _extractStats(row);
      final samples = await _fetchSamples(db, trip.id);
      trips.add(
        PersistedTrip(
          trip: trip,
          route: samples,
          distanceKm: stats.$1,
          averageSpeedKph: stats.$2,
        ),
      );
    }
    return trips;
  }

  Trip _mapTrip(Map<String, Object?> row) {
    return Trip(
      id: row['id']! as String,
      startTime: DateTime.parse(row['start_time']! as String),
      endTime: DateTime.parse(row['end_time']! as String),
      startPosition: GeoPoint(
        latitude: (row['start_lat']! as num).toDouble(),
        longitude: (row['start_lng']! as num).toDouble(),
      ),
      endPosition: GeoPoint(
        latitude: (row['end_lat']! as num).toDouble(),
        longitude: (row['end_lng']! as num).toDouble(),
      ),
      startOdometer: (row['start_odometer']! as num).toDouble(),
      endOdometer: (row['end_odometer']! as num).toDouble(),
      vehicleId: row['vehicle_id']! as String,
      vehicle: Vehicle(
        id: row['vehicle_id']! as String,
        displayName: row['vehicle_name']! as String,
      ),
      category: TripCategory.values.firstWhere(
        (value) => value.name == row['category'] as String?,
        orElse: () => TripCategory.business,
      ),
      startAddress: row['start_address'] as String?,
      endAddress: row['end_address'] as String?,
      notes: row['notes'] as String?,
      tags: (jsonDecode(row['tags'] as String? ?? '[]') as List<dynamic>)
          .cast<String>(),
    );
  }

  Future<List<TripLocationSample>> _fetchSamples(Database db, String tripId) async {
    final rows = await db.query(
      'trip_location_samples',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'sample_index ASC',
    );
    return rows
        .map(
          (row) => TripLocationSample(
            position: GeoPoint(
              latitude: (row['latitude']! as num).toDouble(),
              longitude: (row['longitude']! as num).toDouble(),
            ),
            recordedAt: DateTime.parse(row['recorded_at']! as String),
            sequence: row['sample_index']! as int,
          ),
        )
        .toList(growable: false);
  }

  (double?, double?) _extractStats(Map<String, Object?> row) {
    return (
      (row['distance_km'] as num?)?.toDouble(),
      (row['average_speed_kph'] as num?)?.toDouble(),
    );
  }
}
