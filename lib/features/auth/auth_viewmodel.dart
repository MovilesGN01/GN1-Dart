import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final UserRepository _repository;

  AuthViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  List<Map<String, dynamic>> _recurringRoutes = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  List<Map<String, dynamic>> get recurringRoutes => _recurringRoutes;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.signIn(email, password);
      if (success) {
        final uid = await _repository.getCurrentUserId();
        if (uid != null) {
          _currentUser = await _repository.getUserProfile(uid);
        }
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadUserProfile(String userId) async {
    _currentUser = await _repository.getUserProfile(userId);
    notifyListeners();
  }

  Future<String?> getCurrentUserId() {
    return _repository.getCurrentUserId();
  }

  Future<int> getQueuePosition(String userId, String rideId) {
    return _repository.getQueuePosition(userId, rideId);
  }

  Future<void> loadRecurringRoutes() async {
    debugPrint('[RecRides] calling getRideRecommendations '
        'with userId=${currentUser?.id}');
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('getRideRecommendations');
      final result = await callable.call({'userId': currentUser?.id ?? ''});

      final data = result.data;
      debugPrint('[RecRides] raw CF response: $data');

      if (data != null && data is List && data.isNotEmpty) {
        _recurringRoutes = data
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item))
            .toList();
        debugPrint('[RecRides] mapped routes: $_recurringRoutes');
        debugPrint('[RecRides] routes count: ${_recurringRoutes.length}');
        notifyListeners();
        return;
      }

      debugPrint('[RecRides] CF returned empty — falling back to Firestore');
    } catch (e) {
      debugPrint('[RecRides] CF failed: $e — falling back to Firestore');
    }

    await _loadRoutesFromUserAnalytics();
  }

  Future<void> _loadRoutesFromUserAnalytics() async {
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _recurringRoutes = [];
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_analytics')
          .doc(userId)
          .get();

      final ids = List<String>.from(
          doc.data()?['recommendedRides'] ?? []);
      debugPrint('[RecRides] direct Firestore ids: $ids');

      final routes = <Map<String, dynamic>>[];
      for (final id in ids) {
        try {
          final rideDoc = await FirebaseFirestore.instance
              .collection('rides')
              .doc(id)
              .get();
          if (rideDoc.exists && rideDoc.data() != null) {
            final d = rideDoc.data()!;
            routes.add({
              'origin': (d['origin'] as String?) ?? '',
              'destination':
                  (d['destination'] as String?) ?? 'Campus Uniandes',
              'count': 0,
            });
          }
        } catch (e) {
          debugPrint('[RecRides] failed to fetch ride $id: $e');
        }
      }

      debugPrint('[RecRides] mapped routes: $routes');
      debugPrint('[RecRides] routes count: ${routes.length}');
      _recurringRoutes = routes;
    } catch (e) {
      debugPrint('[RecRides] user_analytics fallback failed: $e');
      _recurringRoutes = [];
    }

    notifyListeners();
  }
}
