import 'package:geocoding/geocoding.dart' as geocoding;

import '../models/geo_point.dart';

/// Thin wrapper over the `geocoding` package that normalises reverse lookup
/// results for the app.
class ReverseGeocodingService {
  const ReverseGeocodingService();

  Future<String?> resolveAddress(GeoPoint point) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) {
        return null;
      }
      final placemark = placemarks.first;
      final segments = <String>[
        if ((placemark.street ?? '').isNotEmpty) placemark.street!,
        if ((placemark.locality ?? '').isNotEmpty) placemark.locality!,
        if ((placemark.administrativeArea ?? '').isNotEmpty)
          placemark.administrativeArea!,
      ];
      if (segments.isEmpty) {
        return placemark.name;
      }
      return segments.join(', ');
    } on Exception {
      return null;
    }
  }
}
