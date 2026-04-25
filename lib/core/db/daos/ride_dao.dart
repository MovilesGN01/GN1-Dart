import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/models/ride_model.dart';
import '../database_helper.dart';
import '../entities/ride_entity.dart';

class RideDao {
  RideDao(this._helper);

  final DatabaseHelper _helper;

  Future<void> insertOrReplaceAll(List<RideModel> rides) async {
    final db = await _helper.database;
    final batch = db.batch();
    for (final ride in rides) {
      batch.insert(
        'rides',
        ride.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<RideModel>> fetchAll() async {
    final db = await _helper.database;
    final rows = await db.query('rides');
    return rows.map((row) => RideEntityExtension.fromDbMap(row)).toList();
  }

  Future<int> count() async {
    final db = await _helper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM rides');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> deleteAll() async {
    final db = await _helper.database;
    await db.delete('rides');
  }

  Future<void> deleteExpiredRides() async {
    final db = await _helper.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final deleted = await db.delete(
      'rides',
      where: 'departure_time < ?',
      whereArgs: [nowMs],
    );
    debugPrint('[SQLite] deleted $deleted expired rides');
  }

  Future<void> deleteStaleRides({
    Duration maxAge = const Duration(hours: 6),
  }) async {
    final db = await _helper.database;
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    final deleted = await db.delete(
      'rides',
      where: 'cached_at < ?',
      whereArgs: [cutoff],
    );
    debugPrint('[SQLite] deleted $deleted stale rides');
  }
}
