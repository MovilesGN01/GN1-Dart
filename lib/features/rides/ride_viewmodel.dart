import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../data/repositories/impl/firebase_ride_repository.dart';
import '../../data/repositories/ride_repository.dart';
import '../../data/models/ride_model.dart';

class RideViewModel extends ChangeNotifier {
  final RideRepository _repository;

  RideViewModel(this._repository) {
    _setupConnectivityListener();
  }

  StreamSubscription<bool>? _connectivitySub;

  void _setupConnectivityListener() {
    _connectivitySub = ConnectivityService().onStatusChanged.listen((isOnline) {
      final wasOffline = isOffline;
      debugPrint('[Connectivity] online=$isOnline '
          'wasOffline=$wasOffline isFromCache=$isFromCache');
      isOffline = !isOnline;
      notifyListeners();
      if (isOnline && (wasOffline || isFromCache)) {
        debugPrint('[Connectivity] triggering reload '
            '(wasOffline=$wasOffline isFromCache=$isFromCache)');
        invalidateAndReload();
      } else if (isOnline) {
        debugPrint('[Connectivity] online, no reload needed');
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search state (Feature 3 / Feature 5)
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

  Future<void> loadAvailableRides() async {
    _isLoading = true;
    _isSearchMode = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = _repository;
      if (repo is FirebaseRideRepository) {
        _rides = await repo.getAvailableRidesWithFallback(
          onCacheStatus: (v) {
            isFromCache = v;
            debugPrint('[RideVM] isFromCache set to $v');
          },
        );
      } else {
        _rides = await _repository.getAvailableRides();
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
