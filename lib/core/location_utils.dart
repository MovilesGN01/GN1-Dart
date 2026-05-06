import 'package:geolocator/geolocator.dart';

abstract final class LocationUtils {
  /// Returns the current GPS position, or null if unavailable.
  static Future<Position?> getCurrentPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  /// Fallback zone name from latitude when reverse geocoding fails.
  static String? zoneFromLatLon(double lat, double lon) {
    if (lat > 4.72) return 'Usaquén';
    if (lat > 4.68) return 'Suba';
    if (lat > 4.64) return 'Chapinero';
    if (lat > 4.60) return 'Teusaquillo';
    if (lat > 4.56) return 'Santa Fe';
    return 'Kennedy';
  }

  /// Legacy: returns zone name directly. Kept for compatibility.
  static Future<String?> detectZone() async {
    final position = await getCurrentPosition();
    if (position == null) return null;
    return zoneFromLatLon(position.latitude, position.longitude);
  }
}
