import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/vehicle.dart';
import '../database/mileage_database.dart';
import '../database/persistence_queue.dart';

class VehicleRepository {
  VehicleRepository({
    MileageDatabase? database,
    PersistenceQueue? queue,
    Uuid? uuid,
  })  : _database = database ?? MileageDatabase.instance,
        _queue = queue ?? PersistenceQueue(),
        _uuid = uuid ?? const Uuid();

  final MileageDatabase _database;
  final PersistenceQueue _queue;
  final Uuid _uuid;

  final StreamController<List<Vehicle>> _vehiclesController =
      StreamController<List<Vehicle>>.broadcast();

  Stream<List<Vehicle>> watchVehicles() {
    unawaited(_emitVehicles());
    return _vehiclesController.stream;
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final db = await _database.database;
    final rows = await db.query('vehicles', orderBy: 'display_name COLLATE NOCASE');
    return rows.map(_mapVehicle).toList();
  }

  Future<Vehicle?> findActiveVehicle() async {
    final db = await _database.database;
    final rows = await db.query(
      'vehicles',
      where: 'is_active = 1',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapVehicle(rows.single);
  }

  Future<Vehicle> upsertVehicle(Vehicle vehicle) {
    return _queue.enqueue(() async {
      final db = await _database.database;
      final record = vehicle.id.isEmpty
          ? vehicle.copyWith(id: _uuid.v4())
          : vehicle;
      await db.insert(
        'vehicles',
        _vehicleToMap(record),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _emitVehicles();
      return record;
    });
  }

  Future<void> deleteVehicle(String id) {
    return _queue.enqueue(() async {
      final db = await _database.database;
      await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
      await _emitVehicles();
    });
  }

  Future<void> setActiveVehicle(String id) {
    return _queue.enqueue(() async {
      final db = await _database.database;
      final batch = db.batch();
      batch.update('vehicles', {'is_active': 0});
      batch.update(
        'vehicles',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      await batch.commit(noResult: true);
      await _emitVehicles();
    });
  }

  Map<String, Object?> _vehicleToMap(Vehicle vehicle) {
    return {
      'id': vehicle.id,
      'display_name': vehicle.displayName,
      'make': vehicle.make,
      'model': vehicle.model,
      'year': vehicle.year,
      'license_plate': vehicle.licensePlate,
      'default_odometer': vehicle.defaultOdometer,
      'is_active': vehicle.isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Vehicle _mapVehicle(Map<String, Object?> row) {
    return Vehicle(
      id: row['id']! as String,
      displayName: row['display_name']! as String,
      make: row['make'] as String?,
      model: row['model'] as String?,
      year: row['year'] as int?,
      licensePlate: row['license_plate'] as String?,
      defaultOdometer: (row['default_odometer'] as num?)?.toDouble(),
      isActive: (row['is_active'] as int? ?? 0) == 1,
    );
  }

  Future<void> _emitVehicles() async {
    final vehicles = await fetchVehicles();
    if (!_vehiclesController.isClosed) {
      _vehiclesController.add(vehicles);
    }
  }
}
