import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

/// Lightweight representation of a location update emitted by the
/// [LocationService].
class LocationSnapshot {
  const LocationSnapshot({
    required this.position,
    required this.timestamp,
    required this.accuracyMeters,
    this.speedMps,
  });

  final GeoPoint position;
  final DateTime timestamp;
  final double accuracyMeters;
  final double? speedMps;

  LocationSnapshot copyWith({
    GeoPoint? position,
    DateTime? timestamp,
    double? accuracyMeters,
    double? speedMps,
  }) {
    return LocationSnapshot(
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      speedMps: speedMps ?? this.speedMps,
    );
  }
}

/// The current permission/service status for the location provider.
class LocationStatus {
  const LocationStatus({
    required this.serviceEnabled,
    required this.permissionState,
    this.error,
  });

  const LocationStatus.initial()
      : serviceEnabled = false,
        permissionState = LocationPermissionState.unknown,
        error = null;

  final bool serviceEnabled;
  final LocationPermissionState permissionState;
  final String? error;

  bool get ready => serviceEnabled && permissionState == LocationPermissionState.granted;

  LocationStatus copyWith({
    bool? serviceEnabled,
    LocationPermissionState? permissionState,
    String? error,
  }) {
    return LocationStatus(
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      permissionState: permissionState ?? this.permissionState,
      error: error,
    );
  }
}

/// Reducer friendly enum for permission state.
enum LocationPermissionState {
  unknown,
  granted,
  denied,
  deniedForever,
}

/// Manages high level GPS lifecycle for the application.
class LocationService {
  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance,
        _statusController = StreamController<LocationStatus>.broadcast(),
        _positionController = StreamController<LocationSnapshot>.broadcast();

  final GeolocatorPlatform _geolocator;
  final StreamController<LocationStatus> _statusController;
  final StreamController<LocationSnapshot> _positionController;

  Stream<LocationStatus> get statusStream => _statusController.stream;
  Stream<LocationSnapshot> get positionStream => _positionController.stream;

  LocationStatus get status => _status;
  LocationStatus _status = const LocationStatus.initial();

  LocationSnapshot? get lastSnapshot => _lastSnapshot;
  LocationSnapshot? _lastSnapshot;

  StreamSubscription<Position>? _subscription;

  /// Checks the current device status and prompts for permission/service
  /// enablement when missing.
  Future<LocationStatus> ensureServiceAndPermissions() async {
    var serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    final status = _status = LocationStatus(
      serviceEnabled: serviceEnabled,
      permissionState: _mapPermission(permission),
      error: _status.error,
    );
    _statusController.add(status);
    return status;
  }

  /// Returns the most up to date position available without mutating the active
  /// stream subscription state. When there is no live location, the last known
  /// reading is returned.
  Future<LocationSnapshot?> getCurrentSnapshot() async {
    try {
      final permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _updateStatus(permission: permission, error: 'Location permissions are denied.');
        return null;
      }

      Position? position;
      try {
        position = await _geolocator.getCurrentPosition();
      } on Exception {
        position = await _geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _updateStatus(error: 'Unable to determine current position.');
        return null;
      }

      final snapshot = _snapshotFromPosition(position);
      _lastSnapshot = snapshot;
      _positionController.add(snapshot);
      _updateStatus(permission: permission);
      return snapshot;
    } on Exception catch (error, stackTrace) {
      _updateStatus(error: error.toString());
      Zone.current.handleUncaughtError(error, stackTrace);
      return null;
    }
  }

  /// Begins streaming location updates. Subsequent calls will cancel the
  /// previous subscription and restart the stream.
  Future<void> startTracking({LocationSettings? settings}) async {
    await ensureServiceAndPermissions();
    final permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _updateStatus(permission: permission, error: 'Location access not granted.');
      return;
    }

    await _subscription?.cancel();
    final stream = _geolocator.getPositionStream(
      locationSettings: settings ?? const LocationSettings(accuracy: LocationAccuracy.best),
    );
    _subscription = stream.listen(
      (position) {
        final snapshot = _snapshotFromPosition(position);
        _lastSnapshot = snapshot;
        _positionController.add(snapshot);
        _updateStatus(permission: permission);
      },
      onError: (Object error, StackTrace stackTrace) {
        _updateStatus(permission: permission, error: error.toString());
        Zone.current.handleUncaughtError(error, stackTrace);
      },
    );
  }

  /// Stops the active position stream without modifying listeners.
  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _positionController.close();
  }

  void _updateStatus({LocationPermission? permission, String? error}) {
    final status = _status = _status.copyWith(
      serviceEnabled: _status.serviceEnabled,
      permissionState: permission == null ? _status.permissionState : _mapPermission(permission),
      error: error,
    );
    _statusController.add(status);
  }

  LocationSnapshot _snapshotFromPosition(Position position) {
    return LocationSnapshot(
      position: GeoPoint(latitude: position.latitude, longitude: position.longitude),
      timestamp: position.timestamp ?? DateTime.now(),
      accuracyMeters: position.accuracy,
      speedMps: position.speed == 0 ? null : position.speed,
    );
  }

  LocationPermissionState _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionState.granted;
      case LocationPermission.denied:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.unknown;
    }
  }
}
