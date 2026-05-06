import '../models/user_model.dart';

abstract class UserRepository {
  /// Returns true on success; throws Exception with user-friendly message on auth failure.
  Future<bool> signIn(String email, String password);

  Future<void> signOut();

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String gender,
    required String vehiclePlate,
  });

  Future<UserModel?> getUserProfile(String userId);

  /// Returns the UID of the currently signed-in user, or null if not signed in.
  Future<String?> getCurrentUserId();

  /// Returns 1-based position in the ride's queue for the given user.
  Future<int> getQueuePosition(String userId, String rideId);

  /// Returns top 2 routes sorted by frequency from rideHistory.
  Future<List<Map<String, dynamic>>> getRecurringRoutes(String userId);
}
