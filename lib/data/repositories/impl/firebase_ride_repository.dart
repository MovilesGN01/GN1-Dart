import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/cache/lru_cache.dart';
import '../../../core/db/daos/ride_dao.dart';
import '../../../core/db/database_helper.dart';
import '../../models/ride_details_model.dart';
import '../../models/ride_model.dart';
import '../ride_repository.dart';

class FirebaseRideRepository implements RideRepository {
  FirebaseRideRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _dao = RideDao(DatabaseHelper());
  }

  final FirebaseFirestore _firestore;
  final LRUCache<String, List<RideModel>> _lruCache = LRUCache(capacity: 50);
  late final RideDao _dao;

  @override
  Future<List<RideModel>> getAvailableRides() async {
    try {
      final snapshot = await _firestore
          .collection('rides')
          .where('status', isEqualTo: 'available')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return RideModel.fromMap(doc.data(), doc.id);
        } catch (e) {
          // ignore: avoid_print
          print('ERROR mapping doc ${doc.id}: $e');
          // ignore: avoid_print
          print('Doc data: ${doc.data()}');
          rethrow;
        }
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('ERROR in getAvailableRides: $e');
      rethrow;
    }
  }

  @override
  Future<List<RideModel>> getMatchingRides(String userId) async {
    final snapshot = await _firestore
        .collection('rides')
        .where('status', isEqualTo: 'available')
        .get();

    return snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<RideDetailsModel> getRideDetails(String rideId) async {
    final rideDoc = await _firestore.collection('rides').doc(rideId).get();

    if (!rideDoc.exists || rideDoc.data() == null) {
      throw Exception('No se encontró el ride.');
    }

    final rideData = rideDoc.data()!;

    final rawDriverId = (rideData['driverId'] as String?) ?? '';
    final driverId = _normalizeDriverId(rawDriverId);

    Map<String, dynamic> driverData = {};
    if (driverId.isNotEmpty) {
      final driverDoc = await _firestore.collection('users').doc(driverId).get();
      if (driverDoc.exists && driverDoc.data() != null) {
        driverData = driverDoc.data()!;
      }
    }

    final departureTime = _readDateTime(rideData['departureTime']) ?? DateTime.now();
    final estimatedArrivalTime = _readDateTime(rideData['estimatedArrivalTime']);

    final estimatedDurationMinutes = estimatedArrivalTime != null
        ? estimatedArrivalTime.difference(departureTime).inMinutes
        : 0;

    final meetingPoints = ((rideData['meetingPoints'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final driverName = _firstNonEmpty([
          rideData['driverName']?.toString(),
          rideData['name']?.toString(),
          driverData['driverName']?.toString(),
          driverData['name']?.toString(),
        ]) ??
        'Conductor';

    final driverRating =
        _readDouble(rideData['driverRating']) ??
        _readDouble(rideData['reputationScore']) ??
        _readDouble(driverData['driverRating']) ??
        _readDouble(driverData['reputationScore']) ??
        0.0;

    final isFemaleDriver =
        (rideData['isFemaleDriver'] as bool?) ??
        ((rideData['gender']?.toString().toLowerCase() == 'female') ||
            (driverData['gender']?.toString().toLowerCase() == 'female'));

    final vehicleModel = _firstNonEmpty([
          rideData['vehicleModel']?.toString(),
          rideData['carModel']?.toString(),
          driverData['vehicleModel']?.toString(),
          driverData['carModel']?.toString(),
        ]) ??
        '';

    final vehiclePlate = _firstNonEmpty([
          rideData['vehiclePlate']?.toString(),
          rideData['plate']?.toString(),
          driverData['vehiclePlate']?.toString(),
          driverData['plate']?.toString(),
        ]) ??
        '';

    final punctualityRate =
        _readDouble(rideData['punctualityRate']) ??
        _readDouble(driverData['punctualityRate']) ??
        0.0;

    final verified =
        (rideData['verified'] as bool?) ??
        (driverData['verified'] as bool?) ??
        false;

    final badges = <String>[
      if (verified) 'Verified student',
      if (driverRating >= 4.7) 'High rating',
      if (punctualityRate >= 0.9) 'Highly punctual',
    ];

    final amenities = <String>[
      if (meetingPoints.length > 1) 'Multiple pickup points',
    ];

    return RideDetailsModel(
      id: rideDoc.id,
      driverId: driverId,
      driverName: driverName,
      driverPhotoUrl: '',
      driverRating: driverRating,
      isFemaleDriver: isFemaleDriver,
      origin: (rideData['origin'] as String?) ?? '',
      destination: (rideData['destination'] as String?) ?? '',
      departureTime: departureTime,
      estimatedDurationMinutes: estimatedDurationMinutes,
      price: _readDouble(rideData['price']) ?? 0.0,
      seatsAvailable:
          (rideData['seatsAvailable'] as num?)?.toInt() ??
          (rideData['seats'] as num?)?.toInt() ??
          0,
      status: (rideData['status'] as String?) ?? 'available',
      zone: (rideData['zone'] as String?) ?? '',
      pickupAddress: meetingPoints.isNotEmpty ? meetingPoints.first : '',
      pickupReference: meetingPoints.length > 1
          ? 'Selecciona uno de los puntos disponibles'
          : '',
      vehicleBrand: '',
      vehicleModel: vehicleModel,
      vehicleColor: '',
      vehiclePlate: vehiclePlate,
      amenities: amenities,
      badges: badges,
      notes: meetingPoints.isNotEmpty
          ? 'Puntos de recogida disponibles: ${meetingPoints.join(', ')}'
          : '',
      isReservedByCurrentUser: false,
      meetingPoints: meetingPoints,
      selectedMeetingPoint: meetingPoints.isNotEmpty ? meetingPoints.first : null,
    );
  }

  @override
  Future<void> reserveRide(String rideId, String userId) async {
    final rideRef = _firestore.collection('rides').doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final rideSnap = await transaction.get(rideRef);

      if (!rideSnap.exists) {
        throw Exception('Ride no encontrado.');
      }

      final data = rideSnap.data()!;
      final seatsAvailable =
          (data['seatsAvailable'] as num?)?.toInt() ??
          (data['seats'] as num?)?.toInt() ??
          0;

      if (seatsAvailable <= 0) {
        throw Exception('No hay asientos disponibles.');
      }

      transaction.update(rideRef, {
        'seatsAvailable': seatsAvailable - 1,
        'seats': seatsAvailable - 1,
      });

      if (userId.isNotEmpty) {
        final passengerRef =
            rideRef.collection('passengers').doc(userId);
        transaction.set(passengerRef, {
          'userId': userId,
          'reservedAt': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      }
    });
  }

  Future<List<RideModel>> getAvailableRidesWithFallback({
    bool forceRefresh = false,
    void Function(bool isFromCache)? onCacheStatus,
  }) async {
    const key = 'available_rides';

    if (!forceRefresh) {
      final cached = _lruCache.get(key);
      if (cached != null) {
        debugPrint('[LRU] hit — ${cached.length} rides');
        onCacheStatus?.call(true);
        return cached;
      }
    }

    try {
      final rides = await getAvailableRides();
      _lruCache.put(key, rides);
      unawaited(_dao.insertOrReplaceAll(rides));
      debugPrint('[Repo] Firestore ok — ${rides.length}');
      onCacheStatus?.call(false);
      return rides;
    } catch (e) {
      debugPrint('[Repo] Firestore failed: $e');
      final local = await _dao.fetchAll();
      if (local.isNotEmpty) {
        _lruCache.put(key, local);
        debugPrint('[SQLite] fallback — ${local.length}');
        onCacheStatus?.call(true);
        return local;
      }
      rethrow;
    }
  }

  void invalidateRideCache() {
    _lruCache.invalidateAll();
  }

  String _normalizeDriverId(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains('/')) {
      final parts = raw.split('/');
      return parts.where((e) => e.trim().isNotEmpty).last;
    }
    return raw;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}