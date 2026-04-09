import 'package:flutter/foundation.dart';
import 'package:uniride/data/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final UserRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> signIn(String email, String password) async {
    if (!email.endsWith('@uniandes.edu.co')) {
      _errorMessage = 'Debes usar tu correo institucional @uniandes.edu.co';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _repository.signIn(email, password);
      _isAuthenticated = success;
      if (!success) {
        _errorMessage = 'Correo o contraseña incorrectos';
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
