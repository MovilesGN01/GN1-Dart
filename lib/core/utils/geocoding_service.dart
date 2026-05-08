import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String displayName;
  final String fullName;
  final double lat;
  final double lon;

  const PlaceSuggestion({
    required this.displayName,
    required this.fullName,
    required this.lat,
    required this.lon,
  });
}

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

  /// Forward geocoding via Nominatim — returns up to 5 place suggestions.
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri =
          Uri.parse('https://nominatim.openstreetmap.org/search').replace(
        queryParameters: {
          'q': '${query.trim()}, Bogotá, Colombia',
          'format': 'json',
          'limit': '5',
          'addressdetails': '1',
          'accept-language': 'es',
        },
      );
      final response = await http
          .get(uri,
              headers: {'User-Agent': 'UniRide/1.0 (university project)'})
          .timeout(const Duration(seconds: 5));

      debugPrint('[Geocoding] status=${response.statusCode} query="$query"');
      if (response.statusCode == 429) {
        debugPrint('[Geocoding] rate-limited by Nominatim — wait a minute');
        return [];
      }
      if (response.statusCode != 200) return [];

      final results = jsonDecode(response.body) as List<dynamic>;
      return results.map((r) {
        final map = r as Map<String, dynamic>;
        return PlaceSuggestion(
          displayName: _shortName(map),
          fullName: map['display_name'] as String,
          lat: double.parse(map['lat'] as String),
          lon: double.parse(map['lon'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Geocoding] search failed: $e');
      return [];
    }
  }

  static String _shortName(Map<String, dynamic> map) {
    final addr = map['address'] as Map<String, dynamic>?;
    if (addr == null) {
      return (map['display_name'] as String)
          .split(',')
          .take(2)
          .join(',')
          .trim();
    }
    final name = addr['amenity'] as String? ??
        addr['building'] as String? ??
        addr['road'] as String? ??
        addr['neighbourhood'] as String? ??
        addr['suburb'] as String?;
    final city = addr['city_district'] as String? ?? addr['suburb'] as String?;
    if (name != null && city != null) return '$name, $city';
    return (map['display_name'] as String)
        .split(',')
        .take(2)
        .join(',')
        .trim();
  }
}
