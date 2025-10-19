import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_category.dart';

class SettingsService {
  SettingsService({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencesFuture;

  static const String _lastCategoryKey = 'settings.last_category';
  static const String _lastVehicleKey = 'settings.last_vehicle';

  Future<void> saveLastCategory(TripCategory category) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_lastCategoryKey, category.name);
  }

  Future<TripCategory?> loadLastCategory() async {
    final prefs = await _preferencesFuture;
    final value = prefs.getString(_lastCategoryKey);
    if (value == null) {
      return null;
    }
    return TripCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => TripCategory.business,
    );
  }

  Future<void> saveLastVehicleId(String vehicleId) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_lastVehicleKey, vehicleId);
  }

  Future<String?> loadLastVehicleId() async {
    final prefs = await _preferencesFuture;
    return prefs.getString(_lastVehicleKey);
  }
}
