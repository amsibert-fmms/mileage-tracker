import 'package:flutter/material.dart';

import '../controllers/trip_controller.dart';
import '../models/trip_category.dart';
import '../models/trip_log_entry.dart';
import '../models/vehicle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const List<Vehicle> _demoVehicles = <Vehicle>[
  Vehicle(id: 'vehicle-1', displayName: 'Sedan · ABC123', make: 'Toyota', model: 'Camry'),
  Vehicle(id: 'vehicle-2', displayName: 'SUV · JKL890', make: 'Honda', model: 'CR-V'),
  Vehicle(id: 'vehicle-3', displayName: 'Hybrid · GREEN1', make: 'Toyota', model: 'Prius'),
];

class _HomeScreenState extends State<HomeScreen> {
  late final TripController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TripController(vehicles: _demoVehicles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final statusText = _buildStatusText();
        final tripHistory = _controller.tripHistory;
        final totalDuration = _controller.totalLoggedDuration;
        final totalDistance = _controller.totalLoggedDistanceKm;

        return Scaffold(
          appBar: AppBar(title: const Text('Mileage Tracker')),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _controller.activeVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Active vehicle',
                    border: OutlineInputBorder(),
                  ),
                  items: _controller.vehicles
                      .map((vehicle) => DropdownMenuItem<String>(
                            value: vehicle.id,
                            child: Text(vehicle.displayName),
                          ))
                      .toList(),
                  onChanged: _controller.tripActive ? null : _controller.setActiveVehicle,
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
                  children: TripCategory.values.map((category) {
                    return ChoiceChip(
                      label: Text(category.label),
                      selected: _controller.selectedCategory == category,
                      onSelected: _controller.tripActive
                          ? null
                          : (_) => _controller.selectCategory(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                if (tripHistory.isNotEmpty)
                  _SummaryCard(
                    totalTrips: tripHistory.length,
                    totalDurationLabel: _formatDuration(totalDuration),
                    totalDistanceLabel: _formatDistanceLong(totalDistance),
                  ),
                if (tripHistory.isNotEmpty) const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: _controller.toggleTrip,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            backgroundColor:
                                _controller.tripActive ? Colors.red : Colors.teal,
                          ),
                          icon: Icon(_controller.tripActive ? Icons.stop : Icons.play_arrow),
                          label: Text(
                            _controller.tripActive ? 'Stop Trip' : 'Start Trip',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tripHistory.isNotEmpty) ...[
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
                    itemCount: tripHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = tripHistory[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.check_circle_outline, color: Colors.teal),
                        title: Text(
                          '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${entry.vehicleName} · ${entry.category.label} · ${_formatDuration(entry.duration)} · ${_formatDistanceShort(entry.distanceKm)} · ${_formatSpeedShort(entry.averageSpeedKph)}',
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildStatusText() {
    if (_controller.tripActive) {
      final startTime = _controller.startTime!;
      final vehicleLabel = _controller.currentVehicle?.displayName ?? 'Unknown vehicle';
      return 'Trip started at ${_formatTime(startTime)}\n'
          'Vehicle: $vehicleLabel\n'
          'Category: ${_controller.selectedCategory.label}\n'
          'Elapsed: ${_formatDuration(_controller.elapsed)}';
    }

    final lastTrip = _controller.lastCompletedTrip;
    if (lastTrip == null) {
      return 'No trip in progress';
    }

    return _formatTripSummary(lastTrip);
  }

  String _formatTripSummary(TripLogEntry entry) {
    return 'Trip from ${_formatTime(entry.startTime)} to ${_formatTime(entry.endTime)}\n'
        'Vehicle: ${entry.vehicleName}\n'
        'Category: ${entry.category.label}\n'
        'Duration: ${_formatDuration(entry.duration)}\n'
        'Distance (est.): ${_formatDistanceLong(entry.distanceKm)}\n'
        'Avg speed (est.): ${_formatSpeedLong(entry.averageSpeedKph)}';
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

  String _formatDistanceShort(double? distanceKm) {
    return '${distanceKm?.toStringAsFixed(1) ?? '--'} km';
  }

  String _formatDistanceLong(double? distanceKm) {
    return distanceKm == null
        ? '-- km'
        : '${distanceKm.toStringAsFixed(1)} km';
  }

  String _formatSpeedShort(double? speedKph) {
    return '${speedKph?.toStringAsFixed(1) ?? '--'} km/h';
  }

  String _formatSpeedLong(double? speedKph) {
    return speedKph == null
        ? '-- km/h'
        : '${speedKph.toStringAsFixed(1)} km/h';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalTrips,
    required this.totalDurationLabel,
    required this.totalDistanceLabel,
  });

  final int totalTrips;
  final String totalDurationLabel;
  final String totalDistanceLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final content = [
              _SummaryTile(
                label: 'Trips',
                value: '$totalTrips',
                icon: Icons.map_outlined,
              ),
              _SummaryTile(
                label: 'Time logged',
                value: totalDurationLabel,
                icon: Icons.schedule_outlined,
              ),
              _SummaryTile(
                label: 'Distance',
                value: totalDistanceLabel,
                icon: Icons.social_distance_outlined,
              ),
            ];

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < content.length; i++) ...[
                    content[i],
                    if (i < content.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: content
                  .map(
                    (tile) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: tile,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.teal.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
