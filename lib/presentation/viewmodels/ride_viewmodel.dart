import 'package:flutter/foundation.dart';
import 'package:uniride/data/models/ride_model.dart';
import 'package:uniride/data/repositories/ride_repository.dart';

class RideViewModel extends ChangeNotifier {
  RideViewModel(this._repository);

  final RideRepository _repository;

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _rides = await _repository.getAvailableRides();
    } catch (e) {
      _errorMessage = 'Error loading rides: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMatchingRides(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _rides = await _repository.getMatchingRides(userId);
    } catch (e) {
      _errorMessage = 'Error loading rides: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
