import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequestModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final double passengerRating;
  final String status;
  final DateTime requestTime;
  final String? passengerPhotoUrl;

  const RideRequestModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    required this.status,
    required this.requestTime,
    this.passengerPhotoUrl,
  });

  factory RideRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final raw = data['requestTime'];
    final DateTime time = raw is Timestamp
        ? raw.toDate()
        : raw is DateTime
            ? raw
            : DateTime.now();

    return RideRequestModel(
      id: doc.id,
      rideId: (data['rideId'] as String?) ?? '',
      passengerId: (data['passengerId'] as String?) ?? '',
      passengerName: (data['passengerName'] as String?) ?? 'Unknown',
      passengerRating: (data['passengerRating'] as num?)?.toDouble() ??
          (data['reputationScore'] as num?)?.toDouble() ??
          0.0,
      status: (data['status'] as String?) ?? 'pending',
      requestTime: time,
      passengerPhotoUrl: data['passengerPhotoUrl'] as String?,
    );
  }

  RideRequestModel copyWith({String? passengerPhotoUrl}) {
    return RideRequestModel(
      id: id,
      rideId: rideId,
      passengerId: passengerId,
      passengerName: passengerName,
      passengerRating: passengerRating,
      status: status,
      requestTime: requestTime,
      passengerPhotoUrl: passengerPhotoUrl ?? this.passengerPhotoUrl,
    );
  }
}
