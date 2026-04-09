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
  final String gender;
  final double punctualityRate;
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
    this.gender = 'male',
    this.punctualityRate = 0.0,
    this.hasRainForecast = false,
  });

  factory RideModel.fromMap(Map<String, dynamic> data, String id) {
    return RideModel(
      id: id,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? '',
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 0.0,
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      departureTime:
          (data['departureTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seatsAvailable: (data['seatsAvailable'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'available',
      zone: data['zone'] as String? ?? '',
      gender: data['gender'] as String? ?? 'male',
      punctualityRate: (data['punctualityRate'] as num?)?.toDouble() ?? 0.0,
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
    String? gender,
    double? punctualityRate,
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
      gender: gender ?? this.gender,
      punctualityRate: punctualityRate ?? this.punctualityRate,
      hasRainForecast: hasRainForecast ?? this.hasRainForecast,
    );
  }
}
