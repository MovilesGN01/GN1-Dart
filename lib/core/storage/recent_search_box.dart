import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'recent_search.dart';

class RecentSearchBox {
  static const _boxName = 'recentSearches';
  static const _maxEntries = 5;

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static void save(String origin, String destination) {
    final box = Hive.box<String>(_boxName);
    final entry = RecentSearch(
      origin: origin,
      destination: destination,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    box.add(jsonEncode(entry.toMap()));

    // Evict oldest entries beyond the limit
    while (box.length > _maxEntries) {
      box.deleteAt(0);
    }
  }

  static List<RecentSearch> getAll() {
    final box = Hive.box<String>(_boxName);
    final list = box.values
        .map((raw) => RecentSearch.fromMap(
            jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return list;
  }
}
