import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/ride_details_model.dart';

/// File-based cache for ride detail snapshots, keyed by `rideId`.
///
/// Used as the second tier (after the in-memory LRU) so that a user that
/// previously opened a ride detail can still review it offline after killing
/// and re-opening the app.
class RideDetailsStore {
  RideDetailsStore({this.fileName = 'ride_details_cache.json'});

  final String fileName;
  Map<String, Map<String, dynamic>>? _memo;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, fileName));
  }

  Future<Map<String, Map<String, dynamic>>> _load() async {
    if (_memo != null) return _memo!;
    try {
      final file = await _file();
      if (!await file.exists()) return _memo = {};
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return _memo = {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _memo = {};
      return _memo = decoded.map(
        (k, v) => MapEntry(
          k.toString(),
          Map<String, dynamic>.from(v as Map),
        ),
      );
    } catch (e) {
      debugPrint('[RideDetailsStore] load failed: $e');
      return _memo = {};
    }
  }

  Future<RideDetailsModel?> read(String rideId) async {
    final all = await _load();
    final raw = all[rideId];
    if (raw == null) return null;
    try {
      return RideDetailsModel.fromMap(raw);
    } catch (e) {
      debugPrint('[RideDetailsStore] parse failed for $rideId: $e');
      return null;
    }
  }

  Future<void> write(RideDetailsModel details) async {
    try {
      final all = await _load();
      all[details.id] = details.toMap();
      final file = await _file();
      await file.writeAsString(jsonEncode(all), flush: false);
    } catch (e) {
      debugPrint('[RideDetailsStore] write failed: $e');
    }
  }
}
