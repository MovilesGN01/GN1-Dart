import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/user_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  final UserRepository _repository;

  RegisterViewModel(this._repository);

  bool isLoading = false;
  bool isOffline = false;
  String? errorMessage;

  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String role = 'passenger';
  String gender = '';
  String vehiclePlate = '';
  bool showVehicleField = false;

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void setRole(String value) {
    role = value;
    showVehicleField = (value == 'driver');
    notifyListeners();
  }

  void setOffline(bool value) {
    isOffline = value;
    notifyListeners();
  }

  String? validateForm() {
    if (name.trim().isEmpty) return 'Name is required';
    if (!email.trim().endsWith('@uniandes.edu.co')) {
      return 'Use your @uniandes.edu.co institutional email';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (password != confirmPassword) return 'Passwords do not match';
    if (gender.isEmpty) return 'Please select your gender';
    if (role == 'driver') {
      final plate = vehiclePlate.trim().toUpperCase();
      if (plate.isEmpty) return 'Vehicle plate is required for drivers';
      final plateRegex = RegExp(r'^[A-Z]{3}\d{3}$');
      if (!plateRegex.hasMatch(plate)) {
        return 'Plate must be 3 letters and 3 numbers (e.g. ABC123)';
      }
    }
    return null;
  }

  Future<void> register(BuildContext context) async {
    final error = validateForm();
    if (error != null) {
      errorMessage = error;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.registerUser(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
        gender: gender,
        vehiclePlate: vehiclePlate.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await prefs.setString('session_user_id', uid);

      if (context.mounted) context.go('/home');
    } catch (e) {
      errorMessage = _friendlyError(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'This email is already registered';
    }
    if (raw.contains('weak-password')) return 'Password is too weak';
    if (raw.contains('network-request-failed')) {
      return 'No internet connection';
    }
    return 'Registration failed. Please try again';
  }
}
