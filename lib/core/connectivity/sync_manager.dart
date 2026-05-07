import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';

class SyncManager {
  SyncManager._internal();
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;

  final DatabaseHelper _db = DatabaseHelper();
  static const _table = 'pending_operations';

  Future<void> enqueue(String operation, String payload) async {
    final db = await _db.database;
    await db.insert(_table, {
      'id': const Uuid().v4(),
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> pendingAll() async {
    final db = await _db.database;
    return db.query(_table, orderBy: 'created_at ASC');
  }

  Future<void> remove(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
