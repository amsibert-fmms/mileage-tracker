import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Centralised access to the SQLite database backing mileage persistence.
class MileageDatabase {
  MileageDatabase._();

  static final MileageDatabase instance = MileageDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final db = await _open();
    _database = db;
    return db;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'mileage_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        make TEXT,
        model TEXT,
        year INTEGER,
        license_plate TEXT,
        default_odometer REAL,
        is_active INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        start_lat REAL NOT NULL,
        start_lng REAL NOT NULL,
        end_lat REAL NOT NULL,
        end_lng REAL NOT NULL,
        start_odometer REAL NOT NULL,
        end_odometer REAL NOT NULL,
        vehicle_id TEXT NOT NULL,
        vehicle_name TEXT NOT NULL,
        category TEXT NOT NULL,
        start_address TEXT,
        end_address TEXT,
        notes TEXT,
        tags TEXT,
        distance_km REAL,
        average_speed_kph REAL,
        created_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(vehicle_id) REFERENCES vehicles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE trip_location_samples (
        trip_id TEXT NOT NULL,
        sample_index INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        PRIMARY KEY(trip_id, sample_index),
        FOREIGN KEY(trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_locations (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        formatted_address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_trips_created_at ON trips(created_at DESC)');
    await db.execute('CREATE INDEX idx_trips_vehicle ON trips(vehicle_id)');
  }
}
