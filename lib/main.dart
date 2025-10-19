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
  final List<_TripCategory> _tripCategories = const <_TripCategory>[
    _TripCategory(id: 'business', label: 'Business'),
    _TripCategory(id: 'personal', label: 'Personal'),
    _TripCategory(id: 'commute', label: 'Commute'),
    _TripCategory(id: 'other', label: 'Other'),
  ];
  String? _activeCategoryId;

  static const int _maxHistoryItems = 5;

  @override
  void initState() {
    super.initState();
    _activeVehicleId = _vehicles.first.id;
    _activeCategoryId = _tripCategories.first.id;
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
        categoryLabel: _currentCategory.label,
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
    return 'Trip from $start to $end · ${record.vehicleName} · ${record.categoryLabel} ($duration)';
  }

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = _currentVehicle.label;
    final categoryLabel = _currentCategory.label;
    final statusText = tripActive
        ? 'Trip started at ${_formatTime(startTime!)}\nVehicle: $vehicleLabel\nCategory: $categoryLabel\nElapsed: ${_formatDuration(elapsed)}'
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
            DropdownButtonFormField<String>(
              value: _activeCategoryId,
              decoration: const InputDecoration(
                labelText: 'Trip category',
                border: OutlineInputBorder(),
              ),
              items: _tripCategories
                  .map((category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.label),
                      ))
                  .toList(),
              onChanged: tripActive
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _activeCategoryId = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
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
                        '${record.vehicleName} · ${record.categoryLabel} · Elapsed ${_formatDuration(record.duration)}'),
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

  _TripCategory get _currentCategory {
    final activeId = _activeCategoryId;
    return _tripCategories.firstWhere(
      (category) => category.id == activeId,
      orElse: () => _tripCategories.first,
    );
  }
}

class _TripRecord {
  const _TripRecord({
    required this.startTime,
    required this.endTime,
    required this.vehicleName,
    required this.categoryLabel,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String vehicleName;
  final String categoryLabel;

  Duration get duration => endTime.difference(startTime);
}

class _Vehicle {
  const _Vehicle({required this.id, required this.label});

  final String id;
  final String label;
}

class _TripCategory {
  const _TripCategory({required this.id, required this.label});

  final String id;
  final String label;
}
