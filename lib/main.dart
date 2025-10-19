import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const MileageTrackerApp());

class MileageTrackerApp extends StatelessWidget {
  const MileageTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mileage Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool tripActive = false;
  DateTime? startTime;
  Duration elapsed = Duration.zero;
  Timer? _timer;
  String? lastTripSummary;
  final List<_TripRecord> _tripHistory = <_TripRecord>[];
  final List<_Vehicle> _vehicles = const <_Vehicle>[
    _Vehicle(id: 'vehicle-1', label: 'Sedan - ABC123'),
    _Vehicle(id: 'vehicle-2', label: 'SUV - JKL890'),
    _Vehicle(id: 'vehicle-3', label: 'Hybrid - GREEN1'),
  ];
  String? _activeVehicleId;
  _TripCategory _selectedCategory = _TripCategory.business;

  static const int _maxHistoryItems = 5;

  @override
  void initState() {
    super.initState();
    _activeVehicleId = _vehicles.first.id;
  }

  void toggleTrip() {
    if (!tripActive) {
      final now = DateTime.now();
      _timer?.cancel();
      setState(() {
        tripActive = true;
        startTime = now;
        elapsed = Duration.zero;
        lastTripSummary = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || startTime == null) return;
        setState(() {
          elapsed = DateTime.now().difference(startTime!);
        });
      });
    } else {
      final stopTime = DateTime.now();
      final record = _TripRecord(
        startTime: startTime!,
        endTime: stopTime,
        vehicleName: _currentVehicle.label,
        category: _selectedCategory,
      );
      _timer?.cancel();
      setState(() {
        tripActive = false;
        elapsed = record.duration;
        startTime = null;
        _tripHistory.insert(0, record);
        if (_tripHistory.length > _maxHistoryItems) {
          _tripHistory.removeRange(
              _maxHistoryItems, _tripHistory.length);
        }
        lastTripSummary = _formatTripSummary(record);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final hoursLabel = hours > 0 ? '${hours}h ' : '';
    final minutesLabel = minutes > 0 || hours > 0 ? '${minutes}m ' : '';
    final secondsLabel = '${seconds}s';
    return '$hoursLabel$minutesLabel$secondsLabel'.trim();
  }

  String _formatTripSummary(_TripRecord record) {
    final start = _formatTime(record.startTime);
    final end = _formatTime(record.endTime);
    final duration = _formatDuration(record.duration);
    return 'Trip from $start to $end · ${record.vehicleName} · ${record.category.label} ($duration)';
  }

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = _currentVehicle.label;
    final statusText = tripActive
        ? 'Trip started at ${_formatTime(startTime!)}\nVehicle: $vehicleLabel\nCategory: ${_selectedCategory.label}\nElapsed: ${_formatDuration(elapsed)}'
        : lastTripSummary ?? 'No trip in progress';

    return Scaffold(
      appBar: AppBar(title: const Text('Mileage Tracker')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _activeVehicleId,
              decoration: const InputDecoration(
                labelText: 'Active vehicle',
                border: OutlineInputBorder(),
              ),
              items: _vehicles
                  .map((vehicle) => DropdownMenuItem<String>(
                        value: vehicle.id,
                        child: Text(vehicle.label),
                      ))
                  .toList(),
              onChanged: tripActive
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _activeVehicleId = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trip purpose',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _TripCategory.values.map((category) {
                return ChoiceChip(
                  label: Text(category.label),
                  selected: _selectedCategory == category,
                  onSelected: tripActive
                      ? null
                      : (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: toggleTrip,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        backgroundColor: tripActive ? Colors.red : Colors.teal,
                      ),
                      icon: Icon(tripActive ? Icons.stop : Icons.play_arrow),
                      label: Text(tripActive ? 'Stop Trip' : 'Start Trip',
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
            if (_tripHistory.isNotEmpty) ...[
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent trips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tripHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = _tripHistory[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline,
                        color: Colors.teal),
                    title: Text(
                      '${_formatTime(record.startTime)} - ${_formatTime(record.endTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                        '${record.vehicleName} · ${record.category.label} · Elapsed ${_formatDuration(record.duration)}'),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  _Vehicle get _currentVehicle {
    final activeId = _activeVehicleId;
    return _vehicles.firstWhere(
      (vehicle) => vehicle.id == activeId,
      orElse: () => _vehicles.first,
    );
  }
}

class _TripRecord {
  const _TripRecord({
    required this.startTime,
    required this.endTime,
    required this.vehicleName,
    required this.category,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String vehicleName;
  final _TripCategory category;

  Duration get duration => endTime.difference(startTime);
}

class _Vehicle {
  const _Vehicle({required this.id, required this.label});

  final String id;
  final String label;
}

enum _TripCategory { business, personal, commute, other }

extension on _TripCategory {
  String get label {
    switch (this) {
      case _TripCategory.business:
        return 'Business';
      case _TripCategory.personal:
        return 'Personal';
      case _TripCategory.commute:
        return 'Commute';
      case _TripCategory.other:
        return 'Other';
    }
  }
}
