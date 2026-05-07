import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/daos/ride_dao.dart';
import '../../../core/db/database_helper.dart';
import '../../../data/models/ride_model.dart';
import '../../../data/repositories/impl/firebase_ride_repository.dart';

class MyRidesViewModel extends ChangeNotifier {
  MyRidesViewModel() {
    _repository = FirebaseRideRepository();
    _dao = RideDao(DatabaseHelper());

    // Check current connectivity immediately (not just on change)
    ConnectivityService().isOnline().then((online) {
      isOffline = !online;
      notifyListeners();
    });

    _connSub = ConnectivityService().onStatusChanged.listen((online) {
      final wasOffline = isOffline;
      isOffline = !online;
      notifyListeners();

      // Auto-refresh when coming back online
      if (online && wasOffline && _lastDriverId != null) {
        loadRides(_lastDriverId!);
      }
    });
  }

  late final FirebaseRideRepository _repository;
  late final RideDao _dao;
  StreamSubscription<bool>? _connSub;

  String? _lastDriverId;

  List<RideModel> rides = [];
  bool isLoading = false;
  bool isOffline = false;
  bool isFromCache = false;
  String? errorMessage;

  Future<void> loadRides(String driverId) async {
    _lastDriverId = driverId;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      rides = await _repository.getDriverRides(driverId);
      unawaited(_dao.insertOrReplaceAll(rides));
      isFromCache = false;
    } catch (e) {
      debugPrint('[MyRides] Firestore failed: $e');
      final now = DateTime.now();
      final cached = await _dao.fetchAll();
      rides = cached
          .where((r) =>
              r.driverId == driverId &&
              (r.departureTime.isAfter(now) || r.status == 'in_progress'))
          .toList()
        ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
      // Only show cache banner if we actually have cached data to show
      isFromCache = rides.isNotEmpty;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}
