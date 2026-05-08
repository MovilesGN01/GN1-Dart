import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import 'connectivity_service.dart';

class SyncManager {
  SyncManager._internal();
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final ConnectivityService _connectivity = ConnectivityService();
  static const _table = 'pending_operations';
  StreamSubscription<bool>? _sub;

  void init() {
    _sub = _connectivity.onStatusChanged.listen((online) {
      if (online) processPending();
    });
  }

  Future<void> enqueue(String type, String payloadJson) async {
    final db = await DatabaseHelper().database;
    await db.insert(_table, {
      'id': const Uuid().v4(),
      'type': type,
      'payload': payloadJson,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    });
    debugPrint('[SyncManager] enqueued $type');
  }

  Future<List<Map<String, dynamic>>> pendingAll() async {
    final db = await DatabaseHelper().database;
    return db.query(_table, orderBy: 'created_at ASC');
  }

  Future<void> remove(String id) async {
    final db = await DatabaseHelper().database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> processPending() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    if (rows.isEmpty) return;

    debugPrint('[SyncManager] processing ${rows.length} pending operations');

    for (final row in rows) {
      final id = row['id'] as String;
      final type = row['type'] as String;
      final payload = row['payload'] as String;
      final retryCount = (row['retry_count'] as int?) ?? 0;

      try {
        if (type == 'reserve_ride') {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          await _functions.httpsCallable('requestRide').call({
            'rideId': data['rideId'],
            'userId': data['userId'],
          });
          await db.delete(_table, where: 'id = ?', whereArgs: [id]);
          debugPrint('[SyncManager] reserve_ride synced: $id');
        } else if (type == 'create_ride') {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          final depTime = DateTime.fromMillisecondsSinceEpoch(
            data['departureTime'] as int,
          );
          if (depTime.isBefore(DateTime.now())) {
            await db.delete(_table, where: 'id = ?', whereArgs: [id]);
            debugPrint('[SyncManager] create_ride expired, discarded: $id');
            continue;
          }
          await _functions.httpsCallable('createRide').call(data);
          await db.delete(_table, where: 'id = ?', whereArgs: [id]);
          debugPrint('[SyncManager] create_ride synced: $id');
        }
      } catch (e) {
        debugPrint('[SyncManager] failed ($type, retry=$retryCount): $e');
        if (retryCount >= 3) {
          await db.delete(_table, where: 'id = ?', whereArgs: [id]);
          debugPrint('[SyncManager] max retries reached, discarded: $id');
        } else {
          await db.update(
            _table,
            {'retry_count': retryCount + 1},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
