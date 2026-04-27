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
  FirebaseRideRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _dao = RideDao(DatabaseHelper());
  }

  final FirebaseFirestore _firestore;
  final LRUCache<String, List<RideModel>> _lruCache =
      LRUCache(capacity: 50);
  late final RideDao _dao;

  // ── Public API ────────────────────────────────────────────────────────────

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
          debugPrint('ERROR mapping doc ${doc.id}: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('ERROR in getAvailableRides: $e');
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

  /// Online-first with LRU → SQLite fallback.
  Future<List<RideModel>> getAvailableRidesWithFallback({
    bool forceRefresh = false,
    void Function(bool isFromCache)? onCacheStatus,
  }) async {
    unawaited(_dao.deleteExpiredRides());
    const key = 'available_rides';

    if (!forceRefresh) {
      final cached = _lruCache.get(key);
      if (cached != null) {
        debugPrint('[LRU] hit — ${cached.length} rides');
        onCacheStatus?.call(false);
        return cached;
      }
    }

    try {
      final rides = await getAvailableRides();
      _lruCache.put(key, rides);
      unawaited(_dao.insertOrReplaceAll(rides));
      debugPrint('[Repo] Firestore ok — ${rides.length} rides');
      onCacheStatus?.call(false);
      return rides;
    } catch (e) {
      debugPrint('[Repo] Firestore failed: $e — fallback SQLite');
      final local = await _dao.fetchAll();
      if (local.isNotEmpty) {
        _lruCache.put(key, local);
        debugPrint('[SQLite] fallback — ${local.length} rides');
        onCacheStatus?.call(true);
        return local;
      }
      rethrow;
    }
  }

  void invalidateRideCache() => _lruCache.invalidateAll();

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
      final driverDoc =
          await _firestore.collection('users').doc(driverId).get();
      if (driverDoc.exists && driverDoc.data() != null) {
        driverData = driverDoc.data()!;
      }
    }

    final departureTime =
        _readDateTime(rideData['departureTime']) ?? DateTime.now();

    return RideDetailsModel(
      id: rideDoc.id,
      driverId: driverId,
      driverName: _firstNonEmpty([
            rideData['driverName']?.toString(),
            rideData['name']?.toString(),
          ]) ??
          'Conductor',
      driverPhotoUrl: '',
      driverRating: _readDouble(rideData['driverRating']) ?? 0.0,
      isFemaleDriver: false,
      origin: (rideData['origin'] as String?) ?? '',
      destination: (rideData['destination'] as String?) ?? '',
      departureTime: departureTime,
      estimatedDurationMinutes: 0,
      price: _readDouble(rideData['price']) ?? 0.0,
      seatsAvailable:
          (rideData['seatsAvailable'] as num?)?.toInt() ?? 0,
      status: (rideData['status'] as String?) ?? 'available',
      zone: (rideData['zone'] as String?) ?? '',
      pickupAddress: '',
      pickupReference: '',
      vehicleBrand: '',
      vehicleModel: '',
      vehicleColor: '',
      vehiclePlate: '',
      amenities: const [],
      badges: const [],
      notes: '',
      isReservedByCurrentUser: false,
      meetingPoints: const [],
      selectedMeetingPoint: null,
    );
  }

  @override
  Future<void> reserveRide(
    String rideId,
    String userId, {
    String selectedMeetingPoint = '',
    String pickupReference = '',
  }) async {
    final rideRef = _firestore.collection('rides').doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final rideSnap = await transaction.get(rideRef);

      if (!rideSnap.exists) throw Exception('Ride no encontrado.');

      final data = rideSnap.data()!;
      final seatsAvailable =
          (data['seatsAvailable'] as num?)?.toInt() ?? 0;

      if (seatsAvailable <= 0) {
        throw Exception('No hay asientos disponibles.');
      }

      transaction.update(rideRef, {
        'seatsAvailable': seatsAvailable - 1,
      });

      final bookingRef = _firestore.collection('rideRequests').doc();
      transaction.set(bookingRef, {
        'rideId': rideId,
        'passengerId': userId,
        'origin': data['origin'],
        'destination': data['destination'],
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    invalidateRideCache();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  String _normalizeDriverId(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains('/')) {
      return raw.split('/').where((e) => e.trim().isNotEmpty).last;
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
