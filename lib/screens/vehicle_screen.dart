import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../services/repositories/vehicle_repository.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({
    super.key,
    required this.repository,
    required this.onActiveVehicleChanged,
  });

  final VehicleRepository repository;
  final ValueChanged<String> onActiveVehicleChanged;

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  late final Stream<List<Vehicle>> _vehicleStream;

  @override
  void initState() {
    super.initState();
    _vehicleStream = widget.repository.watchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage vehicles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVehicleEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add vehicle'),
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: _vehicleStream,
        builder: (context, snapshot) {
          final vehicles = snapshot.data ?? const <Vehicle>[];
          if (vehicles.isEmpty) {
            return const Center(
              child: Text('Add your first vehicle to start logging mileage.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _VehicleTile(
                vehicle: vehicle,
                onEdit: () => _openVehicleEditor(context, vehicle: vehicle),
                onDelete: () => _confirmDelete(context, vehicle),
                onSetActive: () async {
                  await widget.repository.setActiveVehicle(vehicle.id);
                  widget.onActiveVehicleChanged(vehicle.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openVehicleEditor(BuildContext context, {Vehicle? vehicle}) async {
    final result = await showModalBottomSheet<Vehicle>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _VehicleEditorSheet(
        vehicle: vehicle,
      ),
    );
    if (result == null) {
      return;
    }
    await widget.repository.upsertVehicle(result);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vehicle == null ? 'Vehicle added' : 'Vehicle updated'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Vehicle vehicle) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove vehicle'),
          content: Text('Are you sure you want to delete ${vehicle.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true) {
      await widget.repository.deleteVehicle(vehicle.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vehicle.displayName} removed')),
      );
    }
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
    required this.onSetActive,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetActive;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    vehicle.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (vehicle.isActive)
                  Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Active'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _buildSubtitle(vehicle),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onSetActive,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Set active'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _buildSubtitle(Vehicle vehicle) {
    final details = <String>[
      if (vehicle.make != null) vehicle.make!,
      if (vehicle.model != null) vehicle.model!,
      if (vehicle.year != null) vehicle.year.toString(),
      if (vehicle.licensePlate != null) 'Plate ${vehicle.licensePlate}',
    ];
    final odometer = vehicle.defaultOdometer;
    if (odometer != null) {
      details.add('Default odo ${odometer.toStringAsFixed(1)} km');
    }
    if (details.isEmpty) {
      return 'No additional details';
    }
    return details.join(' · ');
  }
}

class _VehicleEditorSheet extends StatefulWidget {
  const _VehicleEditorSheet({this.vehicle});

  final Vehicle? vehicle;

  @override
  State<_VehicleEditorSheet> createState() => _VehicleEditorSheetState();
}

class _VehicleEditorSheetState extends State<_VehicleEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _licenseController;
  late final TextEditingController _odometerController;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _nameController = TextEditingController(text: vehicle?.displayName ?? '');
    _makeController = TextEditingController(text: vehicle?.make ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _yearController = TextEditingController(text: vehicle?.year?.toString() ?? '');
    _licenseController = TextEditingController(text: vehicle?.licensePlate ?? '');
    _odometerController =
        TextEditingController(text: vehicle?.defaultOdometer?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licenseController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.vehicle == null ? 'Add vehicle' : 'Edit vehicle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _makeController,
              decoration: const InputDecoration(
                labelText: 'Make',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'License plate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _odometerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Default odometer (km)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a display name.')),
                      );
                      return;
                    }
                    final odometer = double.tryParse(_odometerController.text.trim());
                    final year = int.tryParse(_yearController.text.trim());
                    final vehicle = (widget.vehicle ??
                            Vehicle(
                              id: '',
                              displayName: name,
                            ))
                        .copyWith(
                      displayName: name,
                      make: _makeController.text.trim().isEmpty ? null : _makeController.text.trim(),
                      model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
                      year: year,
                      licensePlate: _licenseController.text.trim().isEmpty
                          ? null
                          : _licenseController.text.trim(),
                      defaultOdometer: odometer,
                    );
                    Navigator.of(context).pop(vehicle);
                  },
                  child: Text(widget.vehicle == null ? 'Add' : 'Save'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
