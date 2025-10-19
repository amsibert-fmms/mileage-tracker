import 'package:flutter/material.dart';

import '../controllers/trip_controller.dart';
import '../models/trip_category.dart';
import '../models/trip_category_summary.dart';
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
        final categorySummaries = _controller.categorySummaries;
        final hasHistory = _controller.hasHistory;
        final tripActive = _controller.tripActive;

        final totalAverageSpeed = _controller.totalLoggedAverageSpeedKph;
        final totalAverageSpeedLabel =
            totalAverageSpeed == null ? null : _formatSpeedLong(totalAverageSpeed);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mileage Tracker'),
            actions: [
              if (hasHistory)
                IconButton(
                  tooltip: 'Clear history',
                  onPressed: tripActive ? null : () => _confirmClearHistory(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
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
                if (hasHistory)
                  _SummaryCard(
                    totalTrips: tripHistory.length,
                    totalDurationLabel: _formatDuration(totalDuration),
                    totalDistanceLabel: _formatDistanceLong(totalDistance),
                    averageSpeedLabel: totalAverageSpeedLabel,
                  ),
                if (hasHistory) const SizedBox(height: 16),
                if (hasHistory)
                  _CategoryBreakdownCard(
                    summaries: categorySummaries,
                    totalTrips: tripHistory.length,
                    durationFormatter: _formatDuration,
                    distanceFormatter: _formatDistanceLong,
                  ),
                if (hasHistory) const SizedBox(height: 24),
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
                if (hasHistory) ...[
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent trips',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      itemCount: tripHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = tripHistory[index];
                        return Dismissible(
                          key: ValueKey(
                            '${entry.startTime.millisecondsSinceEpoch}-${entry.endTime.millisecondsSinceEpoch}-${entry.vehicleName}',
                          ),
                          direction:
                              tripActive ? DismissDirection.none : DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                          onDismissed: tripActive
                              ? null
                              : (_) => _handleTripDismissed(
                                    context: context,
                                    index: index,
                                    entry: entry,
                                  ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.teal,
                            ),
                            title: Text(
                              '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${entry.vehicleName} · ${entry.category.label} · Elapsed ${_formatDuration(entry.duration)} · ${_formatDistanceShort(entry.distanceKm)} · ${_formatSpeedShort(entry.averageSpeedKph)}',
                            ),
                          ),
                        );
                      },
                    ),
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

  void _handleTripDismissed({
    required BuildContext context,
    required int index,
    required TripLogEntry entry,
  }) {
    final removed = _controller.removeTripAt(index);
    if (removed == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Removed trip starting at ${_formatTime(removed.startTime)}',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _controller.restoreTrip(removed, index: index),
          ),
        ),
      );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    if (_controller.tripActive || _controller.tripHistory.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear trip history?'),
          content: const Text(
            'This will permanently remove all logged trips from the demo session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _controller.clearHistory();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Trip history cleared')),
        );
    }
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({
    required this.summaries,
    required this.totalTrips,
    required this.durationFormatter,
    required this.distanceFormatter,
  });

  final List<TripCategorySummary> summaries;
  final int totalTrips;
  final String Function(Duration duration) durationFormatter;
  final String Function(double? distanceKm) distanceFormatter;

  @override
  Widget build(BuildContext context) {
    final entries = summaries.where((summary) => summary.tripCount > 0).toList();
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trip breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final summary in entries) ...[
              _CategoryBreakdownTile(
                summary: summary,
                percentage: totalTrips == 0 ? 0 : summary.tripCount / totalTrips,
                durationFormatter: durationFormatter,
                distanceFormatter: distanceFormatter,
              ),
              if (summary != entries.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownTile extends StatelessWidget {
  const _CategoryBreakdownTile({
    required this.summary,
    required this.percentage,
    required this.durationFormatter,
    required this.distanceFormatter,
  });

  final TripCategorySummary summary;
  final double percentage;
  final String Function(Duration duration) durationFormatter;
  final String Function(double? distanceKm) distanceFormatter;

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(percentage * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              summary.category.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${summary.tripCount} trips · $percentLabel',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.teal.shade50,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Time: ${durationFormatter(summary.totalDuration)} · Distance: ${distanceFormatter(summary.totalDistanceKm)}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalTrips,
    required this.totalDurationLabel,
    required this.totalDistanceLabel,
    this.averageSpeedLabel,
  });

  final int totalTrips;
  final String totalDurationLabel;
  final String totalDistanceLabel;
  final String? averageSpeedLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final tiles = <Widget>[
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

            if (averageSpeedLabel != null) {
              tiles.add(
                _SummaryTile(
                  label: 'Avg speed',
                  value: averageSpeedLabel!,
                  icon: Icons.speed_outlined,
                ),
              );
            }

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    tiles[i],
                    if (i < tiles.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tiles
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
