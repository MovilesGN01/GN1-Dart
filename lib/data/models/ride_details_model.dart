import 'package:cloud_firestore/cloud_firestore.dart';

class RideDetailsModel {
  final String id;
  final String driverId;
  final String driverName;
  final double driverRating;
  final String driverPhotoUrl;

  final String origin;
  final String destination;
  final DateTime departureTime;
  final int estimatedDurationMinutes;
  final double price;
  final int seatsAvailable;
  final String status;
  final String zone;

  final String pickupAddress;
  final String pickupReference;

  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;

  final List<String> amenities;
  final List<String> badges;
  final String notes;
  final bool isFemaleDriver;
  final bool isReservedByCurrentUser;

  final List<String> meetingPoints;
  final String? selectedMeetingPoint;

  const RideDetailsModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.driverPhotoUrl,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.estimatedDurationMinutes,
    required this.price,
    required this.seatsAvailable,
    required this.status,
    required this.zone,
    required this.pickupAddress,
    required this.pickupReference,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.amenities,
    required this.badges,
    required this.notes,
    required this.isFemaleDriver,
    required this.isReservedByCurrentUser,
    required this.meetingPoints,
    required this.selectedMeetingPoint,
  });

  factory RideDetailsModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final pickup = Map<String, dynamic>.from(
      (data['pickup'] as Map?) ?? const {},
    );

    final vehicle = Map<String, dynamic>.from(
      (data['vehicle'] as Map?) ?? const {},
    );

    final rawMeetingPoints = (data['meetingPoints'] as List?) ?? const [];
    final meetingPoints = rawMeetingPoints
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final selectedMeetingPoint = data['selectedMeetingPoint'] as String? ??
        (meetingPoints.isNotEmpty ? meetingPoints.first : null);

    return RideDetailsModel(
      id: data['id'] as String? ?? '',
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? 'Unknown driver',
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 0.0,
      driverPhotoUrl: data['driverPhotoUrl'] as String? ?? '',
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      departureTime: parseDate(data['departureTime']),
      estimatedDurationMinutes:
          (data['estimatedDurationMinutes'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      seatsAvailable: (data['seatsAvailable'] as num?)?.toInt() ??
          (data['seats'] as num?)?.toInt() ??
          0,
      status: data['status'] as String? ?? 'available',
      zone: data['zone'] as String? ?? '',
      pickupAddress: pickup['address'] as String? ??
          (meetingPoints.isNotEmpty ? meetingPoints.first : ''),
      pickupReference: pickup['reference'] as String? ?? '',
      vehicleBrand: vehicle['brand'] as String? ?? '',
      vehicleModel: vehicle['model'] as String? ??
          data['carModel'] as String? ??
          '',
      vehicleColor: vehicle['color'] as String? ?? '',
      vehiclePlate: vehicle['plate'] as String? ??
          data['plate'] as String? ??
          '',
      amenities: List<String>.from(data['amenities'] ?? const []),
      badges: List<String>.from(data['badges'] ?? const []),
      notes: data['notes'] as String? ?? '',
      isFemaleDriver: data['isFemaleDriver'] as bool? ?? false,
      isReservedByCurrentUser:
          data['isReservedByCurrentUser'] as bool? ?? false,
      meetingPoints: meetingPoints,
      selectedMeetingPoint: selectedMeetingPoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'driverPhotoUrl': driverPhotoUrl,
      'origin': origin,
      'destination': destination,
      'departureTime': departureTime.toIso8601String(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'price': price,
      'seatsAvailable': seatsAvailable,
      'status': status,
      'zone': zone,
      'pickup': {
        'address': pickupAddress,
        'reference': pickupReference,
      },
      'vehicle': {
        'brand': vehicleBrand,
        'model': vehicleModel,
        'color': vehicleColor,
        'plate': vehiclePlate,
      },
      'amenities': amenities,
      'badges': badges,
      'notes': notes,
      'isFemaleDriver': isFemaleDriver,
      'isReservedByCurrentUser': isReservedByCurrentUser,
      'meetingPoints': meetingPoints,
      'selectedMeetingPoint': selectedMeetingPoint,
    };
  }

  RideDetailsModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    double? driverRating,
    String? driverPhotoUrl,
    String? origin,
    String? destination,
    DateTime? departureTime,
    int? estimatedDurationMinutes,
    double? price,
    int? seatsAvailable,
    String? status,
    String? zone,
    String? pickupAddress,
    String? pickupReference,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlate,
    List<String>? amenities,
    List<String>? badges,
    String? notes,
    bool? isFemaleDriver,
    bool? isReservedByCurrentUser,
    List<String>? meetingPoints,
    String? selectedMeetingPoint,
  }) {
    return RideDetailsModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTime: departureTime ?? this.departureTime,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      price: price ?? this.price,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      status: status ?? this.status,
      zone: zone ?? this.zone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupReference: pickupReference ?? this.pickupReference,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      amenities: amenities ?? this.amenities,
      badges: badges ?? this.badges,
      notes: notes ?? this.notes,
      isFemaleDriver: isFemaleDriver ?? this.isFemaleDriver,
      isReservedByCurrentUser:
          isReservedByCurrentUser ?? this.isReservedByCurrentUser,
      meetingPoints: meetingPoints ?? this.meetingPoints,
      selectedMeetingPoint:
          selectedMeetingPoint ?? this.selectedMeetingPoint,
    );
  }
}