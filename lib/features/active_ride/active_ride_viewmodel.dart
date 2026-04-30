import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../data/models/ride_status_model.dart';
import '../../data/repositories/ride_repository.dart';

class ActiveRideViewModel extends ChangeNotifier {
  ActiveRideViewModel(this._repository, this.rideId) {
    _subscribe();
    _setupConnectivityListener();
  }

  final RideRepository _repository;
  final String rideId;

  RideStatusModel? currentStatus;
  bool isOffline = false;

  bool get isCompleted =>
      currentStatus != null &&
      RideStatusModel.isCompletedStatus(currentStatus!.status);

  StreamSubscription<RideStatusModel>? _rideSub;
  StreamSubscription<bool>? _connectivitySub;

  void _subscribe() {
    _rideSub?.cancel();
    _rideSub = _repository.listenToRideStatus(rideId).listen(
      (status) {
        currentStatus = status;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ActiveRideVM] listener error: $e');
      },
    );
  }

  void _setupConnectivityListener() {
    _connectivitySub =
        ConnectivityService().onStatusChanged.listen((online) {
      final wasOffline = isOffline;
      isOffline = !online;
      notifyListeners();
      if (online && wasOffline) {
        debugPrint('[ActiveRideVM] reconnected — re-subscribing');
        _subscribe();
      }
    });
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
