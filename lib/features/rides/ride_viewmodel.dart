import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/impl/firebase_ride_repository.dart';
import '../../data/repositories/ride_repository.dart';

class RideViewModel extends ChangeNotifier {
  RideViewModel(this._repository) {
    _setupConnectivityListener();
  }

  final RideRepository _repository;
  StreamSubscription<bool>? _connectivitySub;

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _isSearchMode = false;
  String _searchOrigin = '';
  String _searchDestination = '';

  bool isFromCache = false;
  bool isOffline = false;

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSearchMode => _isSearchMode;
  String get searchOrigin => _searchOrigin;
  String get searchDestination => _searchDestination;

  void _setupConnectivityListener() {
    _connectivitySub = ConnectivityService().onStatusChanged.listen((isOnline) {
      final wasOffline = isOffline;

      isOffline = !isOnline;
      notifyListeners();

      if (isOnline && (wasOffline || isFromCache)) {
        debugPrint('[RideVM] back online — reloading rides');
        invalidateAndReload();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> loadAvailableRides() async {
    _isLoading = true;
    _isSearchMode = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = _repository;

      if (repo is FirebaseRideRepository) {
        _rides = await repo.getAvailableRidesWithFallback(
          onCacheStatus: (fromCache) {
            isFromCache = fromCache;
            isOffline = fromCache;
            debugPrint('[RideVM] isFromCache set to $fromCache');
          },
        );
      } else {
        _rides = await _repository.getAvailableRides();
        isFromCache = false;
        isOffline = false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> invalidateAndReload() async {
    debugPrint('[RideVM] invalidateAndReload started');

    final repo = _repository;
    if (repo is FirebaseRideRepository) {
      repo.invalidateRideCache();
    }

    await loadAvailableRides();

    debugPrint('[RideVM] invalidateAndReload done, isFromCache=$isFromCache');
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