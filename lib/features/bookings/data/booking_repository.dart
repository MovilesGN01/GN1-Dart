import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_local_datasource.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository({
    FirebaseFirestore? firestore,
    BookingLocalDatasource? localDatasource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _local = localDatasource ?? BookingLocalDatasource.instance;

  final FirebaseFirestore _firestore;
  final BookingLocalDatasource _local;

  Future<List<BookingModel>> getMyBookings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('rideRequests')
          .where('passengerId', isEqualTo: userId)
          .get();

      final bookings = snapshot.docs.map(BookingModel.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await _local.cacheBookings(
        userId,
        bookings.map((b) => b.toSqliteRow()).toList(),
      );

      return bookings;
    } catch (_) {
      final rows = await _local.getCachedBookings(userId);
      return rows.map(BookingModel.fromSqliteRow).toList();
    }
  }

  Future<BookingModel> getBookingById(String bookingId) async {
    final doc =
        await _firestore.collection('rideRequests').doc(bookingId).get();
    if (!doc.exists) throw Exception('No se encontró la reserva.');
    return BookingModel.fromDoc(doc);
  }

  Future<String> savePendingBooking({
    required String rideId,
    required String userId,
    required String driverId,
    required String driverName,
    required String origin,
    required String destination,
    required String selectedMeetingPoint,
    required String pickupReference,
    required double price,
    required DateTime departureTime,
  }) async {
    return _local.insertPendingBooking(
      rideId: rideId,
      userId: userId,
      driverId: driverId,
      driverName: driverName,
      origin: origin,
      destination: destination,
      selectedMeetingPoint: selectedMeetingPoint,
      pickupReference: pickupReference,
      price: price,
      seatsReserved: 1,
      departureTime: departureTime,
    );
  }

  Future<List<BookingModel>> getPendingBookings(String userId) async {
    final rows = await _local.getPendingBookings(userId);
    return rows.map(BookingModel.fromPendingRow).toList();
  }

  Future<void> deletePendingBooking(String localId) async {
    await _local.deletePendingBooking(localId);
  }
}
