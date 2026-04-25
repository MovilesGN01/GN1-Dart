import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String? localId;
  final String rideId;
  final String passengerId;
  final String driverId;
  final String driverName;
  final String origin;
  final String destination;
  final String selectedMeetingPoint;
  final String pickupReference;
  final String status;
  final double price;
  final int seatsReserved;
  final DateTime departureTime;
  final DateTime createdAt;
  final bool isLocalOnly;

  const BookingModel({
    required this.id,
    this.localId,
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.selectedMeetingPoint,
    required this.pickupReference,
    required this.status,
    required this.price,
    required this.seatsReserved,
    required this.departureTime,
    required this.createdAt,
    this.isLocalOnly = false,
  });

  factory BookingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookingModel(
      id: doc.id,
      rideId: data['rideId']?.toString() ?? '',
      passengerId: data['passengerId']?.toString() ?? '',
      driverId: data['driverId']?.toString() ?? '',
      driverName: data['driverName']?.toString() ?? 'Conductor',
      origin: data['origin']?.toString() ?? '',
      destination: data['destination']?.toString() ?? '',
      selectedMeetingPoint: data['selectedMeetingPoint']?.toString() ?? '',
      pickupReference: data['pickupReference']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seatsReserved: (data['seatsReserved'] as num?)?.toInt() ?? 1,
      departureTime: _parseDate(data['departureTime']),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  factory BookingModel.fromSqliteRow(Map<String, dynamic> row) {
    return BookingModel(
      id: row['id'] as String,
      rideId: row['ride_id'] as String,
      passengerId: row['passenger_id'] as String,
      driverId: row['driver_id'] as String,
      driverName: row['driver_name'] as String,
      origin: row['origin'] as String,
      destination: row['destination'] as String,
      selectedMeetingPoint: row['selected_meeting_point'] as String,
      pickupReference: row['pickup_reference'] as String,
      status: row['status'] as String,
      price: (row['price'] as num).toDouble(),
      seatsReserved: row['seats_reserved'] as int,
      departureTime:
          DateTime.fromMillisecondsSinceEpoch(row['departure_time'] as int),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  factory BookingModel.fromPendingRow(Map<String, dynamic> row) {
    return BookingModel(
      id: row['local_id'] as String,
      localId: row['local_id'] as String,
      rideId: row['ride_id'] as String,
      passengerId: row['passenger_id'] as String,
      driverId: row['driver_id'] as String,
      driverName: row['driver_name'] as String,
      origin: row['origin'] as String,
      destination: row['destination'] as String,
      selectedMeetingPoint: row['selected_meeting_point'] as String,
      pickupReference: row['pickup_reference'] as String,
      status: 'pending_sync',
      price: (row['price'] as num).toDouble(),
      seatsReserved: row['seats_reserved'] as int,
      departureTime:
          DateTime.fromMillisecondsSinceEpoch(row['departure_time'] as int),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      isLocalOnly: true,
    );
  }

  Map<String, dynamic> toSqliteRow() => {
        'id': id,
        'ride_id': rideId,
        'passenger_id': passengerId,
        'driver_id': driverId,
        'driver_name': driverName,
        'origin': origin,
        'destination': destination,
        'selected_meeting_point': selectedMeetingPoint,
        'pickup_reference': pickupReference,
        'status': status,
        'price': price,
        'seats_reserved': seatsReserved,
        'departure_time': departureTime.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
