import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'uniride.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rides (
        id TEXT PRIMARY KEY,
        driver_id TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        driver_rating REAL NOT NULL,
        driver_gender TEXT NOT NULL DEFAULT 'male',
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        zone TEXT NOT NULL DEFAULT '',
        departure_time INTEGER NOT NULL,
        seats_available INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'available',
        price REAL NOT NULL,
        punctuality_rate REAL NOT NULL DEFAULT 0.0,
        cached_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_rides_zone ON rides(zone)');
    await db.execute('CREATE INDEX idx_rides_status ON rides(status)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // TODO: add future migrations here
  }
}
