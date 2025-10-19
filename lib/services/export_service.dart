import 'dart:io';

import '../models/trip_log_entry.dart';
import 'repositories/trip_repository.dart';

class TripExportService {
  TripExportService(this._tripRepository);

  final TripRepository _tripRepository;

  /// Builds a CSV string for all persisted trips. An optional [trips] override
  /// is provided for tests or partial exports.
  Future<String> buildCsv({List<PersistedTrip>? trips}) async {
    final data = trips ?? await _tripRepository.fetchTrips(limit: 1000);
    final buffer = StringBuffer()
      ..writeln(
        'Trip ID,Start Time,End Time,Vehicle,Category,Duration (minutes),Distance (km),Average Speed (kph),Start Address,End Address,Notes',
      );
    for (final persisted in data) {
      final entry = TripLogEntry.fromTrip(
        persisted.trip,
        route: persisted.route,
        distanceKm: persisted.distanceKm,
        averageSpeedKph: persisted.averageSpeedKph,
      );
      buffer.writeln(_rowForEntry(entry));
    }
    return buffer.toString();
  }

  Future<File> saveCsvToFile(String path) async {
    final csv = await buildCsv();
    final file = File(path);
    await file.writeAsString(csv);
    return file;
  }

  Future<void> exportToGoogleSheets(GoogleSheetsClient client) async {
    final persisted = await _tripRepository.fetchTrips(limit: 1000);
    final rows = persisted
        .map(
          (trip) => _sheetRow(
            TripLogEntry.fromTrip(
              trip.trip,
              route: trip.route,
              distanceKm: trip.distanceKm,
              averageSpeedKph: trip.averageSpeedKph,
            ),
          ),
        )
        .toList(growable: false);
    await client.syncRows(rows);
  }

  String _rowForEntry(TripLogEntry entry) {
    final durationMinutes = entry.duration.inMinutes;
    final distance = entry.distanceKm?.toStringAsFixed(2) ?? '';
    final averageSpeed = entry.averageSpeedKph?.toStringAsFixed(2) ?? '';
    return [
      entry.id,
      entry.startTime.toIso8601String(),
      entry.endTime.toIso8601String(),
      entry.vehicleName,
      entry.category.label,
      durationMinutes,
      distance,
      averageSpeed,
      entry.startAddress ?? '',
      entry.endAddress ?? '',
      entry.notes ?? '',
    ].map(_escapeCsv).join(',');
  }

  Map<String, dynamic> _sheetRow(TripLogEntry entry) {
    return {
      'id': entry.id,
      'startTime': entry.startTime.toIso8601String(),
      'endTime': entry.endTime.toIso8601String(),
      'vehicle': entry.vehicleName,
      'category': entry.category.name,
      'durationMinutes': entry.duration.inMinutes,
      'distanceKm': entry.distanceKm,
      'averageSpeedKph': entry.averageSpeedKph,
      'startAddress': entry.startAddress,
      'endAddress': entry.endAddress,
      'startLatitude': entry.startPosition.latitude,
      'startLongitude': entry.startPosition.longitude,
      'endLatitude': entry.endPosition.latitude,
      'endLongitude': entry.endPosition.longitude,
      'route': entry.route
          .map(
            (sample) => {
              'lat': sample.position.latitude,
              'lng': sample.position.longitude,
              'timestamp': sample.recordedAt.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  String _escapeCsv(Object? value) {
    final stringValue = value?.toString() ?? '';
    if (stringValue.contains(',') || stringValue.contains('\n')) {
      return '"${stringValue.replaceAll('"', '""')}"';
    }
    return stringValue;
  }
}

abstract class GoogleSheetsClient {
  Future<void> syncRows(List<Map<String, dynamic>> rows);
}

/// Fallback client that mirrors the data locally when Google Sheets is not yet
/// connected. This allows QA to verify the export payload without credentials.
class FileMirroringSheetsClient implements GoogleSheetsClient {
  FileMirroringSheetsClient(this.filePath);

  final String filePath;

  @override
  Future<void> syncRows(List<Map<String, dynamic>> rows) async {
    final file = File(filePath);
    final jsonString = rows.map((row) => row.toString()).join('\n');
    await file.writeAsString(jsonString);
  }
}
