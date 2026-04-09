// MockImplementation — to be replaced with FirebaseUserRepository in next iteration

import 'package:uniride/data/models/user_model.dart';
import 'package:uniride/data/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  static const _mockUser = UserModel(
    id: 'user_001',
    name: 'Felipe',
    email: 'f.garcia@uniandes.edu.co',
    reputationScore: 4.7,
    punctualityRate: 0.95,
    ridesPerMonth: 12,
    savedRoute: 'Chapinero → Campus',
  );

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUser;
  }

  @override
  Future<int> getQueuePosition(String userId, String rideId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockUser.reputationScore > 4.0) return 1;
    if (_mockUser.reputationScore > 3.0) return 2;
    return 3;
  }

  @override
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return email.endsWith('@uniandes.edu.co');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
