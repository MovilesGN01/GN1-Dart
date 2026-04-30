import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../data/repositories/ride_repository.dart';
import '../bookings/data/booking_repository.dart';

class RateRideViewModel extends ChangeNotifier {
  RateRideViewModel(this._rideRepository, this._bookingRepository);

  final RideRepository _rideRepository;
  final BookingRepository _bookingRepository;

  bool _isSubmitting = false;
  bool _submitted = false;
  bool _alreadyRated = false;
  bool _isOffline = false;
  String? _error;

  StreamSubscription<bool>? _connectivitySub;

  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;
  bool get alreadyRated => _alreadyRated;
  bool get isOffline => _isOffline;
  String? get error => _error;

  Future<void> init() async {
    _isOffline = !(await ConnectivityService().isOnline());
    _connectivitySub =
        ConnectivityService().onStatusChanged.listen((online) {
      _isOffline = !online;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Returns true if sent online, false if queued offline.
  Future<bool> submitRating({
    required String rideId,
    required String driverId,
    required String userId,
    required int stars,
  }) async {
    if (_isSubmitting || _submitted) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final alreadyPending = await _bookingRepository
          .hasPendingRatingForRide(rideId, userId);
      if (alreadyPending) {
        _submitted = true;
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final online = await ConnectivityService().isOnline();
      if (!online) {
        await _bookingRepository.savePendingRating(
          rideId: rideId,
          userId: userId,
          driverId: driverId,
          rating: stars,
        );
        _submitted = true;
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      await _rideRepository.submitRating(rideId: rideId, rating: stars);
      _submitted = true;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        _alreadyRated = true;
        _submitted = true;
      } else {
        await _saveOfflineIfNotPending(
            rideId: rideId,
            userId: userId,
            driverId: driverId,
            rating: stars);
        _submitted = true;
      }
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (_) {
      await _saveOfflineIfNotPending(
          rideId: rideId,
          userId: userId,
          driverId: driverId,
          rating: stars);
      _submitted = true;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveOfflineIfNotPending({
    required String rideId,
    required String userId,
    required String driverId,
    required int rating,
  }) async {
    try {
      final alreadyPending = await _bookingRepository
          .hasPendingRatingForRide(rideId, userId);
      if (!alreadyPending) {
        await _bookingRepository.savePendingRating(
          rideId: rideId,
          userId: userId,
          driverId: driverId,
          rating: rating,
        );
      }
    } catch (e) {
      debugPrint('[RateVM] failed to save pending rating: $e');
    }
  }

  String? get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
