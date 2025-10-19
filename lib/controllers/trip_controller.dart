import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/trip_category.dart';
import '../models/trip_log_entry.dart';
import '../models/vehicle.dart';
import '../services/distance_estimator.dart';

class TripController extends ChangeNotifier {
  TripController({
    required List<Vehicle> vehicles,
    DistanceEstimator? distanceEstimator,
    int maxHistoryItems = 5,
  })  : _vehicles = List<Vehicle>.unmodifiable(vehicles),
        _distanceEstimator = distanceEstimator ?? const DistanceEstimator(),
        _maxHistoryItems = maxHistoryItems {
    if (_vehicles.isNotEmpty) {
      _activeVehicleId = _vehicles.first.id;
    }
  }

  final List<Vehicle> _vehicles;
  final DistanceEstimator _distanceEstimator;
  final int _maxHistoryItems;

  bool _tripActive = false;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  TripLogEntry? _lastCompletedTrip;
  Timer? _timer;

  final List<TripLogEntry> _tripHistory = <TripLogEntry>[];
  TripCategory _selectedCategory = TripCategory.business;
  String? _activeVehicleId;

  List<Vehicle> get vehicles => _vehicles;
  bool get tripActive => _tripActive;
  DateTime? get startTime => _startTime;
  Duration get elapsed => _elapsed;
  TripLogEntry? get lastCompletedTrip => _lastCompletedTrip;
  List<TripLogEntry> get tripHistory => List<TripLogEntry>.unmodifiable(_tripHistory);
  TripCategory get selectedCategory => _selectedCategory;
  String? get activeVehicleId => _activeVehicleId;
  Vehicle get currentVehicle =>
      _vehicles.firstWhere((vehicle) => vehicle.id == _activeVehicleId,
          orElse: () => _vehicles.first);

  void setActiveVehicle(String vehicleId) {
    if (_tripActive || _activeVehicleId == vehicleId) {
      return;
    }
    _activeVehicleId = vehicleId;
    notifyListeners();
  }

  void selectCategory(TripCategory category) {
    if (_tripActive || _selectedCategory == category) {
      return;
    }
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleTrip() {
    if (_tripActive) {
      _stopTrip();
    } else {
      _startTrip();
    }
  }

  void _startTrip() {
    _timer?.cancel();
    _tripActive = true;
    _startTime = DateTime.now();
    _elapsed = Duration.zero;
    _lastCompletedTrip = null;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!hasListeners || _startTime == null) {
        return;
      }
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    });

    notifyListeners();
  }

  void _stopTrip() {
    if (_startTime == null) {
      return;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!);
    final distanceKm = _distanceEstimator.estimateDistanceKm(duration);
    final averageSpeedKph =
        _distanceEstimator.averageSpeedKmPerHour(distanceKm: distanceKm, duration: duration);

    final entry = TripLogEntry(
      startTime: _startTime!,
      endTime: endTime,
      vehicleName: currentVehicle.displayName,
      category: _selectedCategory,
      duration: duration,
      distanceKm: distanceKm,
      averageSpeedKph: averageSpeedKph,
    );

    _timer?.cancel();
    _timer = null;
    _tripActive = false;
    _elapsed = duration;
    _startTime = null;
    _lastCompletedTrip = entry;

    _tripHistory.insert(0, entry);
    if (_tripHistory.length > _maxHistoryItems) {
      _tripHistory.removeRange(_maxHistoryItems, _tripHistory.length);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
