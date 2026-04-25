import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  /// Returns a human-readable address from lat/lon using
  /// OpenStreetMap Nominatim. Returns null if the request fails.
  static Future<String?> getAddressFromCoords({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'es',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'UniRide/1.0 (university project)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      if (address == null) {
        return data['display_name'] as String?;
      }

      // Priority: road + house_number, then neighbourhood/suburb
      final road = address['road'] as String?;
      final number = address['house_number'] as String?;
      final neighbourhood = address['neighbourhood'] as String? ??
          address['suburb'] as String? ??
          address['city_district'] as String?;

      if (road != null) {
        final base = number != null ? '$road #$number' : road;
        return neighbourhood != null ? '$base, $neighbourhood' : base;
      }

      return neighbourhood ?? data['display_name'] as String?;
    } catch (e) {
      debugPrint('[Geocoding] failed: $e');
      return null;
    }
  }
}
