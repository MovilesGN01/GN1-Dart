import 'package:flutter/foundation.dart';

import '../../data/repositories/ride_repository.dart';
import '../../data/models/ride_model.dart';

class RideViewModel extends ChangeNotifier {
  final RideRepository _repository;

  RideViewModel(this._repository);

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAvailableRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rides = await _repository.getAvailableRides();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMatchingRides(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rides = await _repository.getMatchingRides(userId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reserveRide(String rideId, String userId) async {
    await _repository.reserveRide(rideId, userId);
    await loadAvailableRides();
  }
}
