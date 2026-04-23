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
    final userId = await _repository.getCurrentUserId();
    if (userId == null) return;
    _recurringRoutes = await _repository.getRecurringRoutes(userId);
    notifyListeners();
  }
}
