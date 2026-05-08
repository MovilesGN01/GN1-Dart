import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/connectivity_service.dart';
import '../../../data/repositories/ride_repository.dart';
import '../data/booking_repository.dart';
import '../models/booking_model.dart';

class MyBookingsViewModel extends ChangeNotifier {
  MyBookingsViewModel(this._bookingRepository, this._rideRepository);

  final BookingRepository _bookingRepository;
  final RideRepository _rideRepository;

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isOffline = false;
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  int _pendingCount = 0;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  List<BookingModel> get bookings => _bookings;
  int get pendingCount => _pendingCount;

  Future<void> load() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _errorMessage = 'Debes iniciar sesión para ver tus reservas.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isOffline = !(await ConnectivityService.instance.isOnline);

      final confirmed = await _bookingRepository.getMyBookings(user.uid);
      final pending = await _bookingRepository.getPendingBookings(user.uid);
      _pendingCount = pending.length;

      // Pending reservations at the top, then confirmed newest-first
      _bookings = [...pending, ...confirmed];

      if (!_isOffline && pending.isNotEmpty) {
        _syncPending(pending, user.uid);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncPending(List<BookingModel> pending, String userId) async {
    _isSyncing = true;
    notifyListeners();

    bool anySynced = false;

    for (final booking in pending) {
      if (booking.localId == null) continue;

      // Expiry guard: discard reservations for rides that already departed
      if (booking.departureTime.isBefore(DateTime.now())) {
        await _bookingRepository.deletePendingBooking(booking.localId!);
        anySynced = true;
        continue;
      }

      try {
        await _rideRepository.reserveRide(
          booking.rideId,
          userId,
          selectedMeetingPoint: booking.selectedMeetingPoint,
          pickupReference: booking.pickupReference,
        );
        await _bookingRepository.deletePendingBooking(booking.localId!);
        anySynced = true;
      } catch (_) {
        // Keep pending — will retry on next load
      }
    }

    _isSyncing = false;
    notifyListeners();

    if (anySynced) await load();
  }
}
