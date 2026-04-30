import 'package:cloud_firestore/cloud_firestore.dart';

class RideStatusModel {
  final String rideId;
  final String driverId;
  final String driverName;
  final double driverRating;
  final String origin;
  final String destination;
  final String status;
  final String selectedMeetingPoint;
  final String pickupReference;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final DateTime? departureTime;

  const RideStatusModel({
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.origin,
    required this.destination,
    required this.status,
    required this.selectedMeetingPoint,
    required this.pickupReference,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    this.departureTime,
  });

  factory RideStatusModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final vehicle =
        Map<String, dynamic>.from((data['vehicle'] as Map?) ?? const {});
    final pickup =
        Map<String, dynamic>.from((data['pickup'] as Map?) ?? const {});
    final meetingPoints =
        List<String>.from((data['meetingPoints'] as List?) ?? const []);

    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return RideStatusModel(
      rideId: doc.id,
      driverId: (data['driverId'] as String?) ?? '',
      driverName: (data['driverName'] as String?) ?? 'Conductor',
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 0.0,
      origin: (data['origin'] as String?) ?? '',
      destination: (data['destination'] as String?) ?? '',
      status: (data['status'] as String?) ?? '',
      selectedMeetingPoint: (data['selectedMeetingPoint'] as String?) ??
          (meetingPoints.isNotEmpty ? meetingPoints.first : ''),
      pickupReference: pickup['reference'] as String? ?? '',
      vehicleBrand: vehicle['brand'] as String? ?? '',
      vehicleModel:
          vehicle['model'] as String? ?? data['carModel'] as String? ?? '',
      vehicleColor: vehicle['color'] as String? ?? '',
      vehiclePlate: vehicle['plate'] as String? ?? data['plate'] as String? ?? '',
      departureTime: parseDate(data['departureTime']),
    );
  }

  static bool isActiveStatus(String s) =>
      s == 'in_progress' || s == 'started' || s == 'active';

  static bool isCompletedStatus(String s) => s == 'completed';
}
