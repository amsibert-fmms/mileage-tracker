import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/geo_point.dart';
import '../models/trip.dart';
import '../models/trip_category.dart';
import '../models/trip_category_summary.dart';
import '../models/trip_log_entry.dart';
import '../models/trip_location_sample.dart';
import '../models/vehicle.dart';
import '../services/distance_estimator.dart';
import '../services/export_service.dart';
import '../services/location_service.dart';
import '../services/repositories/trip_repository.dart';
import '../services/repositories/vehicle_repository.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/settings_service.dart';

class TripController extends ChangeNotifier {
  TripController({
    required TripRepository tripRepository,
    required VehicleRepository vehicleRepository,
    required LocationService locationService,
    required ReverseGeocodingService reverseGeocodingService,
    required SettingsService settingsService,
    TripExportService? exportService,
    DistanceEstimator distanceEstimator = const DistanceEstimator(),
    int maxHistoryItems = 5,
  })  : _tripRepository = tripRepository,
        _vehicleRepository = vehicleRepository,
        _locationService = locationService,
        _reverseGeocodingService = reverseGeocodingService,
        _settingsService = settingsService,
        _exportService = exportService ?? TripExportService(tripRepository),
        _distanceEstimator = distanceEstimator,
        _maxHistoryItems = maxHistoryItems {
    _vehicleSubscription = _vehicleRepository.watchVehicles().listen(_onVehiclesChanged);
    _tripSubscription = _tripRepository
        .watchRecentTrips(limit: _maxHistoryItems)
        .listen(_onTripsChanged);
    _locationSubscription = _locationService.statusStream.listen((status) {
      _locationStatus = status;
      _locationError = status.error;
      notifyListeners();
    });
    _positionSubscription = _locationService.positionStream.listen((snapshot) {
      if (_tripActive) {
        _activeRoute.add(
          TripLocationSample(
            position: snapshot.position,
            recordedAt: snapshot.timestamp,
            sequence: _activeRoute.length,
          ),
        );
        _locationError = null;
        notifyListeners();
      }
    });
    unawaited(_loadInitialState());
  }

  final TripRepository _tripRepository;
  final VehicleRepository _vehicleRepository;
  final LocationService _locationService;
  final ReverseGeocodingService _reverseGeocodingService;
  final SettingsService _settingsService;
  final TripExportService _exportService;
  final DistanceEstimator _distanceEstimator;
  final int _maxHistoryItems;

  StreamSubscription<List<Vehicle>>? _vehicleSubscription;
  StreamSubscription<List<PersistedTrip>>? _tripSubscription;
  StreamSubscription<LocationStatus>? _locationSubscription;
  StreamSubscription<LocationSnapshot>? _positionSubscription;
  Timer? _timer;

  bool _loading = true;
  bool _tripActive = false;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  TripLogEntry? _lastCompletedTrip;
  List<Vehicle> _vehicles = <Vehicle>[];
  List<TripLogEntry> _tripHistory = <TripLogEntry>[];
  TripCategory _selectedCategory = TripCategory.business;
  String? _activeVehicleId;
  LocationStatus _locationStatus = const LocationStatus.initial();
  final List<TripLocationSample> _activeRoute = <TripLocationSample>[];
  PersistedTrip? _pendingUndoTrip;
  String? _locationError;
  double? _startOdometerInput;
  double? _endOdometerInput;

  bool get loading => _loading;
  bool get tripActive => _tripActive;
  DateTime? get startTime => _startTime;
  Duration get elapsed => _elapsed;
  TripLogEntry? get lastCompletedTrip => _lastCompletedTrip;
  List<Vehicle> get vehicles => _vehicles;
  List<TripLogEntry> get tripHistory => List<TripLogEntry>.unmodifiable(_tripHistory);
  TripCategory get selectedCategory => _selectedCategory;
  String? get activeVehicleId => _activeVehicleId;
  bool get hasHistory => _tripHistory.isNotEmpty;
  LocationStatus get locationStatus => _locationStatus;
  String? get locationError => _locationError;
  double? get startOdometerInput => _startOdometerInput;
  double? get endOdometerInput => _endOdometerInput;

  List<TripCategorySummary> get categorySummaries {
    final aggregates = <TripCategory, _MutableCategorySummary>{
      for (final category in TripCategory.values)
        category: _MutableCategorySummary(),
    };
    for (final entry in _tripHistory) {
      final aggregate = aggregates[entry.category]!;
      aggregate.tripCount++;
      aggregate.totalDuration += entry.duration;
      final distance = entry.distanceKm;
      if (distance != null) {
        aggregate.totalDistanceKm += distance;
        aggregate.hasDistance = true;
      }
    }
    return TripCategory.values
        .map(
          (category) => TripCategorySummary(
            category: category,
            tripCount: aggregates[category]!.tripCount,
            totalDuration: aggregates[category]!.totalDuration,
            totalDistanceKm: aggregates[category]!.hasDistance
                ? aggregates[category]!.totalDistanceKm
                : null,
          ),
        )
        .toList(growable: false);
  }

  Vehicle? get currentVehicle {
    if (_vehicles.isEmpty) {
      return null;
    }
    if (_activeVehicleId == null) {
      return _vehicles.firstWhere((vehicle) => vehicle.isActive, orElse: () => _vehicles.first);
    }
    return _vehicles.firstWhere(
      (vehicle) => vehicle.id == _activeVehicleId,
      orElse: () => _vehicles.first,
    );
  }

  bool get hasVehicles => _vehicles.isNotEmpty;

  Duration get totalLoggedDuration => _tripHistory.fold<Duration>(
        Duration.zero,
        (total, entry) => total + entry.duration,
      );

  double? get totalLoggedDistanceKm {
    double runningTotal = 0;
    var hasValue = false;
    for (final entry in _tripHistory) {
      final distance = entry.distanceKm;
      if (distance != null) {
        runningTotal += distance;
        hasValue = true;
      }
    }
    return hasValue ? runningTotal : null;
  }

  double? get totalLoggedAverageSpeedKph {
    final totalDistance = totalLoggedDistanceKm;
    if (totalDistance == null) {
      return null;
    }
    final totalDurationSeconds = totalLoggedDuration.inSeconds;
    if (totalDurationSeconds <= 0) {
      return null;
    }
    final hours = totalDurationSeconds / 3600;
    return totalDistance / hours;
  }

  Future<void> toggleTrip() async {
    if (_tripActive) {
      await _stopTrip();
    } else {
      await _startTrip();
    }
  }

  Future<void> _startTrip() async {
    if (_vehicles.isEmpty) {
      return;
    }
    final status = await _locationService.ensureServiceAndPermissions();
    _locationStatus = status;
    if (!status.ready) {
      _locationError = status.error ?? 'Location permissions are required to start a trip.';
      notifyListeners();
      return;
    }

    final initialSnapshot = await _locationService.getCurrentSnapshot();
    if (initialSnapshot == null) {
      _locationError = 'Unable to read current GPS position.';
      notifyListeners();
      return;
    }

    _timer?.cancel();
    _tripActive = true;
    _startTime = DateTime.now();
    _elapsed = Duration.zero;
    _lastCompletedTrip = null;
    _locationError = null;
    _activeRoute
      ..clear()
      ..add(
        TripLocationSample(
          position: initialSnapshot.position,
          recordedAt: initialSnapshot.timestamp,
          sequence: 0,
        ),
      );
    _startOdometerInput ??= currentVehicle?.defaultOdometer ?? 0;
    _endOdometerInput = null;

    await _locationService.startTracking();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!hasListeners || _startTime == null) {
        return;
      }
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _stopTrip() async {
    if (_startTime == null) {
      return;
    }

    final startedAt = _startTime!;
    Duration computedDuration = Duration.zero;
    double? closingOdometer = _startOdometerInput;

    try {
      await _locationService.stopTracking();
      final finalSnapshot = await _locationService.getCurrentSnapshot();
      if (finalSnapshot != null) {
        _activeRoute.add(
          TripLocationSample(
            position: finalSnapshot.position,
            recordedAt: finalSnapshot.timestamp,
            sequence: _activeRoute.length,
          ),
        );
      }

      computedDuration = DateTime.now().difference(startedAt);
      final routePoints = _activeRoute.map((sample) => sample.position).toList();
      final startPosition = routePoints.isNotEmpty ? routePoints.first : finalSnapshot?.position;
      final endPosition = routePoints.isNotEmpty ? routePoints.last : finalSnapshot?.position;
      if (startPosition == null || endPosition == null) {
        _locationError = 'Trip ended without GPS coordinates.';
        return;
      }

      final distanceKm = _distanceEstimator.distanceFromRoute(computedDuration, routePoints);
      final averageSpeedKph = _distanceEstimator.averageSpeedKmPerHour(
        distanceKm: distanceKm,
        duration: computedDuration,
      );

      final startAddressFuture = _reverseGeocodingService.resolveAddress(startPosition);
      final endAddressFuture = _reverseGeocodingService.resolveAddress(endPosition);
      final addresses = await Future.wait<String?>([startAddressFuture, endAddressFuture]);

      final startOdometer = _startOdometerInput ?? currentVehicle?.defaultOdometer ?? 0;
      final endOdometer = _endOdometerInput ?? (startOdometer + distanceKm);

      final vehicle = currentVehicle;
      final trip = Trip(
        id: '',
        startTime: startedAt,
        endTime: startedAt.add(computedDuration),
        startPosition: startPosition,
        endPosition: endPosition,
        startOdometer: startOdometer,
        endOdometer: endOdometer,
        vehicleId: vehicle?.id ?? 'unknown',
        vehicle: vehicle,
        category: _selectedCategory,
        startAddress: addresses.first,
        endAddress: addresses.last,
        tags: <String>[_selectedCategory.name],
      );

      final persisted = await _tripRepository.createTrip(
        trip: trip,
        route: List<TripLocationSample>.from(_activeRoute),
        distanceKm: distanceKm,
        averageSpeedKph: averageSpeedKph,
      );
      _lastCompletedTrip = _toLogEntry(persisted);
      _locationError = null;
      closingOdometer = persisted.trip.endOdometer;
    } finally {
      _timer?.cancel();
      _timer = null;
      _tripActive = false;
      _elapsed = computedDuration;
      _startTime = null;
      _activeRoute.clear();
      _pendingUndoTrip = null;
      if (closingOdometer != null) {
        _startOdometerInput = closingOdometer;
      }
      _endOdometerInput = null;
      notifyListeners();
    }
  }

  Future<void> setActiveVehicle(String? vehicleId) async {
    if (vehicleId == null) {
      return;
    }
    _activeVehicleId = vehicleId;
    await _vehicleRepository.setActiveVehicle(vehicleId);
    await _settingsService.saveLastVehicleId(vehicleId);
    notifyListeners();
  }

  Future<void> selectCategory(TripCategory category) async {
    _selectedCategory = category;
    await _settingsService.saveLastCategory(category);
    notifyListeners();
  }

  void setStartOdometer(double? value) {
    _startOdometerInput = value;
    notifyListeners();
  }

  void setEndOdometer(double? value) {
    _endOdometerInput = value;
    notifyListeners();
  }

  Future<TripLogEntry?> removeTripAt(int index) async {
    if (_tripActive || index < 0 || index >= _tripHistory.length) {
      return null;
    }
    final entry = _tripHistory[index];
    final persisted = await _tripRepository.deleteTrip(entry.id);
    _pendingUndoTrip = persisted;
    return entry;
  }

  Future<void> restoreTrip(TripLogEntry entry) async {
    if (_pendingUndoTrip == null) {
      return;
    }
    await _tripRepository.restoreTrip(_pendingUndoTrip!);
    _pendingUndoTrip = null;
    _lastCompletedTrip = entry;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (_tripActive || _tripHistory.isEmpty) {
      return;
    }
    await _tripRepository.clearHistory();
    _pendingUndoTrip = null;
    _lastCompletedTrip = null;
    notifyListeners();
  }

  Future<String> exportTripsToCsv(String path) {
    return _exportService.saveCsvToFile(path).then((file) => file.path);
  }

  Future<void> exportTripsToGoogleSheets(GoogleSheetsClient client) {
    return _exportService.exportToGoogleSheets(client);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vehicleSubscription?.cancel();
    _tripSubscription?.cancel();
    _locationSubscription?.cancel();
    _positionSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final lastCategory = await _settingsService.loadLastCategory();
    if (lastCategory != null) {
      _selectedCategory = lastCategory;
    }
    final lastVehicleId = await _settingsService.loadLastVehicleId();
    _activeVehicleId = lastVehicleId;
    _vehicles = await _vehicleRepository.fetchVehicles();
    if (_activeVehicleId == null && _vehicles.isNotEmpty) {
      final active = _vehicles.firstWhere((vehicle) => vehicle.isActive, orElse: () => _vehicles.first);
      _activeVehicleId = active.id;
    }
    final trips = await _tripRepository.fetchTrips(limit: _maxHistoryItems);
    _updateTripHistory(trips);
    _loading = false;
    notifyListeners();
  }

  void _onVehiclesChanged(List<Vehicle> vehicles) {
    _vehicles = vehicles;
    if (_activeVehicleId == null && vehicles.isNotEmpty) {
      final active = vehicles.firstWhere((vehicle) => vehicle.isActive, orElse: () => vehicles.first);
      _activeVehicleId = active.id;
    }
    notifyListeners();
  }

  void _onTripsChanged(List<PersistedTrip> trips) {
    _updateTripHistory(trips);
    notifyListeners();
  }

  void _updateTripHistory(List<PersistedTrip> trips) {
    _tripHistory = trips.map(_toLogEntry).toList(growable: false);
    _lastCompletedTrip = _tripHistory.isEmpty ? null : _tripHistory.first;
  }

  TripLogEntry _toLogEntry(PersistedTrip persisted) {
    return TripLogEntry.fromTrip(
      persisted.trip,
      route: persisted.route,
      distanceKm: persisted.distanceKm,
      averageSpeedKph: persisted.averageSpeedKph,
    );
  }
}

class _MutableCategorySummary {
  int tripCount = 0;
  Duration totalDuration = Duration.zero;
  double totalDistanceKm = 0;
  bool hasDistance = false;
}
