import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  // Also supports non-singleton call style used by develop's RideViewModel:
  // ConnectivityService().onStatusChanged
  factory ConnectivityService() => instance;

  final Connectivity _connectivity = Connectivity();

  /// One-shot check — true if any network interface is up.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Continuous stream — emits true when online, false when offline.
  /// Compatible with develop branch RideViewModel usage:
  /// `ConnectivityService().onStatusChanged.listen(...)`.
  Stream<bool> get onStatusChanged => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));

  /// Alias kept for backward compatibility within this branch.
  Stream<bool> get onConnectivityChanged => onStatusChanged;
}
