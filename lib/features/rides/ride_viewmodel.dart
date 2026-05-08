import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/db/daos/ride_dao.dart';
import '../../core/db/database_helper.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/impl/firebase_ride_repository.dart';
import '../../data/repositories/ride_repository.dart';

class RideViewModel extends ChangeNotifier {
  RideViewModel(this._repository) {
    _dao = RideDao(DatabaseHelper());
    _setupConnectivityListener();
  }

  final RideRepository _repository;
  late final RideDao _dao;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<QuerySnapshot>? _ridesSub;

  List<RideModel> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _isSearchMode = false;
  String _searchOrigin = '';
  String _searchDestination = '';

  bool isFromCache = false;
  bool isOffline = false;
  Set<String> requestedRideIds = {};

  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSearchMode => _isSearchMode;
  String get searchOrigin => _searchOrigin;
  String get searchDestination => _searchDestination;

  void _setupConnectivityListener() {
    _connectivitySub = ConnectivityService().onStatusChanged.listen((isOnline) {
      isOffline = !isOnline;
      notifyListeners();
      if (isOnline && isFromCache) {
        // Reconnected — re-subscribe to get live data
        loadAvailableRides();
      }
    });
  }

  @override
  void dispose() {
    _ridesSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Subscribes to a real-time Firestore stream of available rides.
  /// The UI updates automatically whenever rides are added, modified or removed.
  void loadAvailableRides() {
    _ridesSub?.cancel();
    _isLoading = true;
    _isSearchMode = false;
    _errorMessage = null;
    notifyListeners();

    _ridesSub = FirebaseFirestore.instance
        .collection('rides')
        .where('status', whereIn: ['available', 'active'])
        .snapshots()
        .listen(
      (snap) {
        final now = DateTime.now();
        _rides = snap.docs
            .map((d) => RideModel.fromMap(d.data(), d.id))
            .where((r) => r.departureTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

        isFromCache = false;
        isOffline = false;
        _isLoading = false;
        _errorMessage = null;

        // Notify immediately so the spinner stops and rides show up
        notifyListeners();

        // Update SQLite cache and requested-ride badges in background
        unawaited(_dao.insertOrReplaceAll(_rides));
        unawaited(_loadRequestedRideIds().then((_) => notifyListeners()));
      },
      onError: (e) {
        debugPrint('[RideVM] stream error: $e — falling back to SQLite');
        _dao.fetchAll().then((cached) {
          final now = DateTime.now();
          _rides = cached
              .where((r) => r.departureTime.isAfter(now))
              .toList()
            ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
          isFromCache = _rides.isNotEmpty;
          isOffline = true;
          _isLoading = false;
          _errorMessage = _rides.isEmpty ? 'No rides available offline.' : null;
          notifyListeners();
          unawaited(_loadRequestedRideIds().then((_) => notifyListeners()));
        });
      },
    );
  }

  Future<void> _loadRequestedRideIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('rideRequests')
          .where('passengerId', isEqualTo: uid)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();
      requestedRideIds = snap.docs.map((d) => d['rideId'] as String).toSet();
    } catch (e) {
      debugPrint('[RideVM] failed to load requested rides: $e');
    }
  }

  void setSearchTerms(String origin, String destination) {
    _searchOrigin = origin;
    _searchDestination = destination;
  }

  Future<void> loadMatchingRides(String userId) async {
    _ridesSub?.cancel(); // stop live updates while in search mode
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
    // Stream will pick up seat count change automatically — no manual reload needed
  }

  /// Kept for backward compatibility — callers can still use this to force
  /// a fresh subscription (e.g. after coming back online).
  Future<void> invalidateAndReload() async {
    if (_repository is FirebaseRideRepository) {
      (_repository as FirebaseRideRepository).invalidateRideCache();
    }
    loadAvailableRides();
  }
}