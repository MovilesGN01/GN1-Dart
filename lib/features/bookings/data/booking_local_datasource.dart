import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class BookingLocalDatasource {
  static final BookingLocalDatasource instance = BookingLocalDatasource._();
  BookingLocalDatasource._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'uniride_bookings.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        ride_id TEXT NOT NULL,
        passenger_id TEXT NOT NULL,
        driver_id TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        selected_meeting_point TEXT NOT NULL,
        pickup_reference TEXT NOT NULL,
        status TEXT NOT NULL,
        price REAL NOT NULL,
        seats_reserved INTEGER NOT NULL,
        departure_time INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_bookings (
        local_id TEXT PRIMARY KEY,
        ride_id TEXT NOT NULL,
        passenger_id TEXT NOT NULL,
        driver_id TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        selected_meeting_point TEXT NOT NULL,
        pickup_reference TEXT NOT NULL,
        price REAL NOT NULL,
        seats_reserved INTEGER NOT NULL,
        departure_time INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> cacheBookings(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    final db = await _database;
    final batch = db.batch();
    batch.delete('bookings', where: 'passenger_id = ?', whereArgs: [userId]);
    for (final row in rows) {
      batch.insert('bookings', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedBookings(String userId) async {
    final db = await _database;
    return db.query(
      'bookings',
      where: 'passenger_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> insertPendingBooking({
    required String rideId,
    required String userId,
    required String driverId,
    required String driverName,
    required String origin,
    required String destination,
    required String selectedMeetingPoint,
    required String pickupReference,
    required double price,
    required int seatsReserved,
    required DateTime departureTime,
  }) async {
    final db = await _database;
    final localId = const Uuid().v4();
    await db.insert('pending_bookings', {
      'local_id': localId,
      'ride_id': rideId,
      'passenger_id': userId,
      'driver_id': driverId,
      'driver_name': driverName,
      'origin': origin,
      'destination': destination,
      'selected_meeting_point': selectedMeetingPoint,
      'pickup_reference': pickupReference,
      'price': price,
      'seats_reserved': seatsReserved,
      'departure_time': departureTime.millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return localId;
  }

  Future<List<Map<String, dynamic>>> getPendingBookings(String userId) async {
    final db = await _database;
    return db.query(
      'pending_bookings',
      where: 'passenger_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deletePendingBooking(String localId) async {
    final db = await _database;
    await db.delete(
      'pending_bookings',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }
}
