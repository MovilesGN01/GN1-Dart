import 'package:geolocator/geolocator.dart';

abstract final class LocationUtils {
  /// Returns the detected neighborhood zone or null if unavailable.
  static Future<String?> detectZone() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));

      return _latToNeighborhood(position.latitude);
    } catch (_) {
      return null;
    }
  }

  static String _latToNeighborhood(double lat) {
    if (lat > 4.72) return 'Usaquén';
    if (lat > 4.68) return 'Suba';
    if (lat > 4.64) return 'Chapinero';
    if (lat > 4.60) return 'Teusaquillo';
    if (lat > 4.56) return 'Santa Fe';
    return 'Kennedy';
  }
}
