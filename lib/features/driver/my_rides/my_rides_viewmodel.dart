import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  final Set<String> _expiringRides = {};

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

    final grace = const Duration(minutes: 15);

    _ridesSub = FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .listen(
      (snap) {
        final now = DateTime.now();
        final allRides = snap.docs.map((d) => RideModel.fromMap(d.data(), d.id)).toList();

        // Auto-expire available/active rides past the 15-min grace window
        for (final r in allRides) {
          if ((r.status == 'available' || r.status == 'active') &&
              r.departureTime.add(grace).isBefore(now) &&
              !_expiringRides.contains(r.id)) {
            _expiringRides.add(r.id);
            FirebaseFunctions.instance
                .httpsCallable('autoExpireRide')
                .call({'rideId': r.id})
                .then((_) => debugPrint('[MyRides] auto-expired ${r.id}'))
                .catchError((e) {
                  debugPrint('[MyRides] autoExpireRide failed for ${r.id}: $e');
                  _expiringRides.remove(r.id);
                });
          }
        }

        rides = allRides
            .where((r) =>
                r.status == 'in_progress' ||
                ((r.status == 'available' || r.status == 'active') &&
                    r.departureTime.add(grace).isAfter(now)))
            .toList()
          ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

        unawaited(_dao.insertOrReplaceAll(rides));
        isFromCache = false;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) async {
        debugPrint('[MyRides] Firestore stream failed: $e');
        final now = DateTime.now();
        final grace = const Duration(minutes: 15);
        final cached = await _dao.fetchAll();
        rides = cached
            .where((r) =>
                r.driverId == driverId &&
                (r.status == 'in_progress' ||
                    ((r.status == 'available' || r.status == 'active') &&
                        r.departureTime.add(grace).isAfter(now))))
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
