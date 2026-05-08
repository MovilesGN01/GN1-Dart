import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'accepted' | 'rejected' | 'new_request'
  final String rideId;
  final String origin;
  final String destination;
  final String message;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.rideId,
    required this.origin,
    required this.destination,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final raw = data['createdAt'];
    final DateTime time = raw is Timestamp
        ? raw.toDate()
        : raw is DateTime
            ? raw
            : DateTime.now();

    return NotificationModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'accepted',
      rideId: (data['rideId'] as String?) ?? '',
      origin: (data['origin'] as String?) ?? '',
      destination: (data['destination'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      read: (data['read'] as bool?) ?? false,
      createdAt: time,
    );
  }
}
