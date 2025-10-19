import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../controllers/trip_controller.dart';
import '../models/trip_category.dart';
import '../models/trip_category_summary.dart';
import '../models/trip_log_entry.dart';
import '../services/distance_estimator.dart';
import '../services/export_service.dart';
import '../services/location_service.dart';
import '../services/repositories/trip_repository.dart';
import '../services/repositories/vehicle_repository.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/settings_service.dart';
import 'vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TripRepository _tripRepository;
  late final VehicleRepository _vehicleRepository;
  late final LocationService _locationService;
  late final ReverseGeocodingService _reverseGeocodingService;
  late final SettingsService _settingsService;
  late final TripController _controller;

  final TextEditingController _startOdometerController = TextEditingController();
  final TextEditingController _endOdometerController = TextEditingController();
  final FocusNode _startOdometerFocus = FocusNode();
  final FocusNode _endOdometerFocus = FocusNode();

  bool _togglingTrip = false;
  String? _lastLocationError;

  @override
  void initState() {
    super.initState();
    _tripRepository = TripRepository();
    _vehicleRepository = VehicleRepository();
    _locationService = LocationService();
    _reverseGeocodingService = const ReverseGeocodingService();
    _settingsService = SettingsService();
    _controller = TripController(
      tripRepository: _tripRepository,
      vehicleRepository: _vehicleRepository,
      locationService: _locationService,
      reverseGeocodingService: _reverseGeocodingService,
      settingsService: _settingsService,
      distanceEstimator: const DistanceEstimator(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _startOdometerController.dispose();
    _endOdometerController.dispose();
    _startOdometerFocus.dispose();
    _endOdometerFocus.dispose();
    super.dispose();
  }

  void _maybeUpdateOdometerFields(TripController controller) {
    final startValue = controller.startOdometerInput;
    if (!_startOdometerFocus.hasFocus) {
      final text = startValue == null ? '' : startValue.toStringAsFixed(1);
      if (_startOdometerController.text != text) {
        _startOdometerController.text = text;
      }
    }
    final endValue = controller.endOdometerInput;
    if (!_endOdometerFocus.hasFocus) {
      final text = endValue == null ? '' : endValue.toStringAsFixed(1);
      if (_endOdometerController.text != text) {
        _endOdometerController.text = text;
      }
    }
  }

  void _maybeShowLocationError(TripController controller) {
    final error = controller.locationError;
    if (error == null) {
      _lastLocationError = null;
      return;
    }
    if (_lastLocationError == error) {
      return;
    }
    _lastLocationError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final controller = _controller;
        _maybeUpdateOdometerFields(controller);
        _maybeShowLocationError(controller);

        final statusBanner = _buildLocationBanner(controller);
        final history = controller.tripHistory;
        final categorySummaries = controller.categorySummaries;
        final totalDuration = controller.totalLoggedDuration;
        final totalDistance = controller.totalLoggedDistanceKm;
        final averageSpeed = controller.totalLoggedAverageSpeedKph;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mileage Tracker'),
            actions: [
              IconButton(
                tooltip: 'Manage vehicles',
                icon: const Icon(Icons.directions_car_filled_outlined),
                onPressed: _openVehicleManagement,
              ),
              PopupMenuButton<_OverflowAction>(
                onSelected: (action) {
                  switch (action) {
                    case _OverflowAction.exportCsv:
                      _exportCsv();
                      break;
                    case _OverflowAction.mirrorSheets:
                      _mirrorToSheets();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _OverflowAction.exportCsv,
                    child: Text('Export trips to CSV'),
                  ),
                  PopupMenuItem(
                    value: _OverflowAction.mirrorSheets,
                    child: Text('Mirror to Google Sheets'),
                  ),
                ],
              ),
              if (controller.hasHistory)
                IconButton(
                  tooltip: 'Clear history',
                  onPressed: controller.tripActive ? null : () => _confirmClearHistory(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      if (statusBanner != null) ...[
                        statusBanner,
                        const SizedBox(height: 12),
                      ],
                      if (!controller.hasVehicles)
                        _EmptyVehiclesCallout(onAddVehicle: _openVehicleManagement),
                      if (controller.hasVehicles)
                        _buildVehicleSelector(controller),
                      if (controller.hasVehicles) const SizedBox(height: 16),
                      if (controller.hasVehicles)
                        _buildCategorySelector(controller),
                      if (controller.hasVehicles) const SizedBox(height: 16),
                      if (controller.hasVehicles)
                        _buildOdometerInputs(controller),
                      if (controller.hasVehicles) const SizedBox(height: 12),
                      if (controller.hasVehicles)
                        _buildTripControls(controller),
                      if (controller.hasHistory) const SizedBox(height: 16),
                      if (controller.hasHistory)
                        _SummaryCard(
                          totalTrips: history.length,
                          totalDurationLabel: _formatDuration(totalDuration),
                          totalDistanceLabel: _formatDistanceLong(totalDistance),
                          averageSpeedLabel: averageSpeed == null ? null : _formatSpeedLong(averageSpeed),
                        ),
                      if (controller.hasHistory) const SizedBox(height: 16),
                      if (controller.hasHistory)
                        _CategoryBreakdownCard(
                          summaries: categorySummaries,
                          totalTrips: history.length,
                          durationFormatter: _formatDuration,
                          distanceFormatter: _formatDistanceLong,
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: controller.hasHistory
                            ? _buildHistoryList(history)
                            : _EmptyHistoryState(onAddVehicle: _openVehicleManagement),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildVehicleSelector(TripController controller) {
    return DropdownButtonFormField<String>(
      value: controller.activeVehicleId,
      decoration: const InputDecoration(
        labelText: 'Active vehicle',
        border: OutlineInputBorder(),
      ),
      items: controller.vehicles
          .map(
            (vehicle) => DropdownMenuItem<String>(
              value: vehicle.id,
              child: Text(vehicle.displayName),
            ),
          )
          .toList(),
      onChanged: controller.tripActive ? null : (value) => controller.setActiveVehicle(value),
    );
  }

  Widget _buildCategorySelector(TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip purpose',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TripCategory.values.map((category) {
            return ChoiceChip(
              label: Text(category.label),
              selected: controller.selectedCategory == category,
              onSelected: controller.tripActive ? null : (_) => controller.selectCategory(category),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOdometerInputs(TripController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _startOdometerController,
            focusNode: _startOdometerFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Start odometer (km)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.setStartOdometer(double.tryParse(value)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _endOdometerController,
            focusNode: _endOdometerFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'End odometer (km)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.setEndOdometer(double.tryParse(value)),
          ),
        ),
      ],
    );
  }

  Widget _buildTripControls(TripController controller) {
    final elapsed = controller.elapsed;
    final isActive = controller.tripActive;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            icon: Icon(isActive ? Icons.stop_circle_outlined : Icons.play_arrow_outlined),
            label: Text(isActive ? 'Stop trip' : 'Start trip'),
            onPressed: _togglingTrip ? null : _toggleTrip,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isActive ? 'Elapsed' : 'Last duration',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _formatDuration(elapsed),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<TripLogEntry> entries) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: ValueKey(entry.id),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
          confirmDismiss: (_) async {
            final removed = await _controller.removeTripAt(index);
            if (removed == null) {
              return false;
            }
            if (!mounted) {
              return true;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trip removed. Undo?'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    unawaited(_controller.restoreTrip(removed));
                  },
                ),
              ),
            );
            return true;
          },
          child: _TripHistoryTile(entry: entry),
        );
      },
    );
  }

  Widget? _buildLocationBanner(TripController controller) {
    final status = controller.locationStatus;
    if (status.ready && controller.locationError == null) {
      return null;
    }
    final message = controller.locationError ??
        (!status.serviceEnabled
            ? 'Enable location services to capture accurate mileage.'
            : 'Grant location permissions to start logging GPS data.');
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_off_outlined, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTrip() async {
    setState(() => _togglingTrip = true);
    try {
      await _controller.toggleTrip();
    } finally {
      if (mounted) {
        setState(() => _togglingTrip = false);
      }
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('This will remove all trips. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear == true) {
      await _controller.clearHistory();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared.')),
      );
    }
  }

  Future<void> _openVehicleManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => VehicleManagementScreen(
          repository: _vehicleRepository,
          onActiveVehicleChanged: (vehicleId) {
            unawaited(_controller.setActiveVehicle(vehicleId));
          },
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'mileage-trips.csv');
    final exportPath = await _controller.exportTripsToCsv(path);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to $exportPath')),
    );
  }

  Future<void> _mirrorToSheets() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'sheets-mirror.txt');
    await _controller.exportTripsToGoogleSheets(FileMirroringSheetsClient(path));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Latest trips mirrored to $path')),
    );
  }
}

class _TripHistoryTile extends StatelessWidget {
  const _TripHistoryTile({required this.entry});

  final TripLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.vehicleName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(entry.category.label),
                  avatar: const Icon(Icons.local_offer_outlined, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatShortDate(entry.startTime)} · ${_formatDuration(entry.duration)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (entry.startAddress != null || entry.endAddress != null) ...[
              const SizedBox(height: 4),
              Text(
                '${entry.startAddress ?? 'Unknown'} → ${entry.endAddress ?? 'Unknown'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _MetricChip(
                  icon: Icons.social_distance_outlined,
                  label: _formatDistanceShort(entry.distanceKm),
                ),
                _MetricChip(
                  icon: Icons.speed_outlined,
                  label: _formatSpeedShort(entry.averageSpeedKph),
                ),
                _MetricChip(
                  icon: Icons.linear_scale_outlined,
                  label: '${entry.odometerDelta.toStringAsFixed(1)} km odometer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _EmptyVehiclesCallout extends StatelessWidget {
  const _EmptyVehiclesCallout({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No vehicles yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Add at least one vehicle before starting a trip.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No trips logged yet.'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddVehicle,
            icon: const Icon(Icons.directions_car_outlined),
            label: const Text('Add a vehicle to get started'),
          ),
        ],
      ),
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

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({
    required this.summaries,
    required this.totalTrips,
    required this.durationFormatter,
    required this.distanceFormatter,
  });

  final List<TripCategorySummary> summaries;
  final int totalTrips;
  final String Function(Duration) durationFormatter;
  final String Function(double?) distanceFormatter;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final summary in summaries)
              _CategoryRow(
                label: summary.category.label,
                countLabel: '${summary.tripCount} trips',
                durationLabel: durationFormatter(summary.totalDuration),
                distanceLabel: distanceFormatter(summary.totalDistanceKm),
                progress: totalTrips == 0 ? 0 : summary.tripCount / totalTrips,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.countLabel,
    required this.durationLabel,
    required this.distanceLabel,
    required this.progress,
  });

  final String label;
  final String countLabel;
  final String durationLabel;
  final String distanceLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(countLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: progress, minHeight: 6),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(durationLabel, style: Theme.of(context).textTheme.bodySmall),
              Text(distanceLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

enum _OverflowAction { exportCsv, mirrorSheets }

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

String _formatDistanceLong(double? distanceKm) {
  if (distanceKm == null) {
    return '0 km';
  }
  return '${distanceKm.toStringAsFixed(2)} km';
}

String _formatDistanceShort(double? distanceKm) {
  if (distanceKm == null) {
    return '—';
  }
  return '${distanceKm.toStringAsFixed(1)} km';
}

String _formatSpeedLong(double speedKph) => '${speedKph.toStringAsFixed(1)} km/h';

String _formatSpeedShort(double? speedKph) {
  if (speedKph == null) {
    return '—';
  }
  return '${speedKph.toStringAsFixed(1)} km/h';
}

String _formatShortDate(DateTime value) {
  return '${value.month}/${value.day}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
