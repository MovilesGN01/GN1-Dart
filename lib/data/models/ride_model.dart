import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String id;
  final String driverId;
  final String driverName;
  final double driverRating;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final double price;
  final int seatsAvailable;
  final String status;
  final String zone;
  final bool isFemaleDriver;

  RideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.price,
    required this.seatsAvailable,
    required this.status,
    required this.zone,
    required this.isFemaleDriver,
  });

  factory RideModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    String normalizeDriverId(String raw) {
      if (raw.isEmpty) return '';
      if (raw.contains('/')) {
        final parts = raw.split('/');
        return parts.where((e) => e.trim().isNotEmpty).last;
      }
      return raw;
    }

    return RideModel(
      id: id,
      driverId: normalizeDriverId((data['driverId'] as String?) ?? ''),
      driverName: (data['driverName'] as String?) ??
          (data['name'] as String?) ??
          'Unknown driver',
      driverRating: (data['driverRating'] as num?)?.toDouble() ??
          (data['reputationScore'] as num?)?.toDouble() ??
          0.0,
      origin: (data['origin'] as String?) ?? '',
      destination: (data['destination'] as String?) ?? '',
      departureTime: parseDate(data['departureTime']),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seatsAvailable: (data['seatsAvailable'] as num?)?.toInt() ??
          (data['seats'] as num?)?.toInt() ??
          0,
      status: (data['status'] as String?) ?? 'available',
      zone: (data['zone'] as String?) ?? '',
      isFemaleDriver: (data['isFemaleDriver'] as bool?) ??
          ((data['gender'] as String?)?.toLowerCase() == 'female'),
    );
  }
}