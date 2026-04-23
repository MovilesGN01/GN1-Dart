// MockImplementation — to be replaced with FirebaseAuthRepository in next iteration
import '../user_repository.dart';
import '../../models/user_model.dart';

class MockUserRepository implements UserRepository {
  @override
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.endsWith('@uniandes.edu.co') && password.isNotEmpty) {
      return true;
    }
    throw Exception('No account found for this email.');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    return const UserModel(
      id: 'mock-user',
      name: 'Usuario Mock',
      email: 'mock@uniandes.edu.co',
      reputationScore: 4.8,
      driverRating: 4.7,
      role: 'passenger',
      verified: true,
    );
  }

  @override
  Future<String?> getCurrentUserId() async {
    return 'mock-user';
  }

  @override
  Future<int> getQueuePosition(String userId, String rideId) async {
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecurringRoutes(String userId) async {
    return [
      {'origin': 'Chapinero', 'destination': 'Campus Uniandes', 'count': 4},
      {'origin': 'Usaquén', 'destination': 'Campus Uniandes', 'count': 2},
    ];
  }
}
