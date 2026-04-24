import 'package:flutter/material.dart';

import '../../data/models/ride_details_model.dart';
import '../../data/repositories/ride_repository.dart';

class RideDetailsViewModel extends ChangeNotifier {
  RideDetailsViewModel(this._repository);

  final RideRepository _repository;

  RideDetailsModel? _ride;
  bool _isLoading = false;
  bool _isReserving = false;
  String? _errorMessage;

  RideDetailsModel? get ride => _ride;
  bool get isLoading => _isLoading;
  bool get isReserving => _isReserving;
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

    if (_isReserving) return false;

    _isReserving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.reserveRide(currentRide.id, '');
      _ride = await _repository.getRideDetails(currentRide.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
}