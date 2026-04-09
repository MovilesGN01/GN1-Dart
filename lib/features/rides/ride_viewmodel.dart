import 'package:flutter/foundation.dart';

import '../../data/repositories/ride_repository.dart';
import '../../data/models/ride_model.dart';

class RideViewModel extends ChangeNotifier {
  final RideRepository _repository;

  RideViewModel(this._repository);

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search state (Feature 3 / Feature 5)
  bool _isSearchMode = false;
  String _searchOrigin = '';
  String _searchDestination = '';

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSearchMode => _isSearchMode;
  String get searchOrigin => _searchOrigin;
  String get searchDestination => _searchDestination;

  Future<void> loadAvailableRides() async {
    _isLoading = true;
    _isSearchMode = false;
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

  void setSearchTerms(String origin, String destination) {
    _searchOrigin = origin;
    _searchDestination = destination;
  }

  Future<void> loadMatchingRides(String userId) async {
    _isLoading = true;
    _isSearchMode = true;
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
