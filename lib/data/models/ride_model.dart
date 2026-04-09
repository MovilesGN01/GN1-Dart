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
  bool hasRainForecast;

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
    this.hasRainForecast = false,
  });

  factory RideModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime departureTime;
    final rawTime = data['departureTime'];
    if (rawTime is Timestamp) {
      departureTime = rawTime.toDate();
    } else if (rawTime is String) {
      departureTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      departureTime = DateTime.now();
    }

    return RideModel(
      id: id,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? '',
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 0.0,
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      departureTime: departureTime,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seatsAvailable: data['seatsAvailable'] as int? ?? 0,
      status: data['status'] as String? ?? 'available',
      zone: data['zone'] as String? ?? '',
    );
  }

  RideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    double? driverRating,
    String? origin,
    String? destination,
    DateTime? departureTime,
    double? price,
    int? seatsAvailable,
    String? status,
    String? zone,
    bool? hasRainForecast,
  }) {
    return RideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      price: price ?? this.price,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      status: status ?? this.status,
      zone: zone ?? this.zone,
      hasRainForecast: hasRainForecast ?? this.hasRainForecast,
    );
  }
}
