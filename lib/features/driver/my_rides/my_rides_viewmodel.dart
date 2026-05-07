import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/daos/ride_dao.dart';
import '../../../core/db/database_helper.dart';
import '../../../data/models/ride_model.dart';

class MyRidesViewModel extends ChangeNotifier {
  MyRidesViewModel() {
    _dao = RideDao(DatabaseHelper());

    ConnectivityService().isOnline().then((online) {
      isOffline = !online;
      notifyListeners();
    });

    _connSub = ConnectivityService().onStatusChanged.listen((online) {
      final wasOffline = isOffline;
      isOffline = !online;
      notifyListeners();

      if (online && wasOffline && _lastDriverId != null) {
        _subscribeToRides(_lastDriverId!);
      }
    });
  }

  late final RideDao _dao;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<QuerySnapshot>? _ridesSub;

  String? _lastDriverId;

  List<RideModel> rides = [];
  bool isLoading = false;
  bool isOffline = false;
  bool isFromCache = false;
  String? errorMessage;

  void loadRides(String driverId) {
    _lastDriverId = driverId;
    _subscribeToRides(driverId);
  }

  void _subscribeToRides(String driverId) {
    _ridesSub?.cancel();

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final now = DateTime.now();

    _ridesSub = FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .listen(
      (snap) {
        rides = snap.docs
            .map((d) => RideModel.fromMap(d.data(), d.id))
            .where((r) =>
                r.departureTime.isAfter(now) || r.status == 'in_progress')
            .toList()
          ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

        unawaited(_dao.insertOrReplaceAll(rides));
        isFromCache = false;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) async {
        debugPrint('[MyRides] Firestore stream failed: $e');
        final cached = await _dao.fetchAll();
        rides = cached
            .where((r) =>
                r.driverId == driverId &&
                (r.departureTime.isAfter(now) || r.status == 'in_progress'))
            .toList()
          ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
        isFromCache = rides.isNotEmpty;
        isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _ridesSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
