import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/connectivity_service.dart';
import '../../data/models/ride_details_model.dart';
import '../../data/repositories/ride_repository.dart';
import '../bookings/data/booking_repository.dart';

class RideDetailsViewModel extends ChangeNotifier {
  RideDetailsViewModel(this._repository, [this._bookingRepository]);

  final RideRepository _repository;
  final BookingRepository? _bookingRepository;

  RideDetailsModel? _ride;
  bool _isLoading = false;
  bool _isReserving = false;
  bool _reservedOffline = false;
  String? _errorMessage;

  RideDetailsModel? get ride => _ride;
  bool get isLoading => _isLoading;
  bool get isReserving => _isReserving;
  bool get reservedOffline => _reservedOffline;
  String? get errorMessage => _errorMessage;

  Future<void> load(String rideId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ride = await _repository.getRideDetails(rideId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectMeetingPoint(String value) {
    if (_ride == null) return;

    _ride = _ride!.copyWith(
      selectedMeetingPoint: value,
      pickupAddress: value,
      pickupReference: 'Punto seleccionado por el pasajero',
    );

    notifyListeners();
  }

  Future<void> refresh() async {
    final currentRideId = _ride?.id;
    if (currentRideId == null || currentRideId.isEmpty) return;

    await load(currentRideId);
  }

  Future<bool> reserve() async {
    final currentRide = _ride;

    if (currentRide == null) {
      _errorMessage = 'No hay un ride cargado.';
      notifyListeners();
      return false;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _errorMessage = 'Debes iniciar sesión para realizar una reserva.';
      notifyListeners();
      return false;
    }

    if (_isReserving) return false;

    _isReserving = true;
    _errorMessage = null;
    _reservedOffline = false;
    notifyListeners();

    try {
      final online = await ConnectivityService.instance.isOnline;

      if (!online) {
        await _savePendingReservation(currentRide, currentUser.uid);
        _reservedOffline = true;
        return true;
      }

      await _repository.reserveRide(
        currentRide.id,
        currentUser.uid,
        selectedMeetingPoint: currentRide.selectedMeetingPoint ?? '',
        pickupReference: currentRide.pickupReference,
      );

      _ride = await _repository.getRideDetails(currentRide.id);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');

      // Offline fallback when a network error occurs mid-transaction
      if (_isNetworkError(msg) && _bookingRepository != null) {
        try {
          await _savePendingReservation(currentRide, currentUser.uid);
          _reservedOffline = true;
          return true;
        } catch (_) {}
      }

      _errorMessage = msg;
      return false;
    } finally {
      _isReserving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _savePendingReservation(
    RideDetailsModel ride,
    String userId,
  ) async {
    await _bookingRepository?.savePendingBooking(
      rideId: ride.id,
      userId: userId,
      driverId: ride.driverId,
      driverName: ride.driverName,
      origin: ride.origin,
      destination: ride.destination,
      selectedMeetingPoint: ride.selectedMeetingPoint ?? '',
      pickupReference: ride.pickupReference,
      price: ride.price,
      departureTime: ride.departureTime,
    );
  }

  bool _isNetworkError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('unavailable') ||
        lower.contains('timeout');
  }
}
