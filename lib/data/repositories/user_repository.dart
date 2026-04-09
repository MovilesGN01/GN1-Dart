import 'package:uniride/data/models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUserProfile(String userId);
  Future<int> getQueuePosition(String userId, String rideId);
  Future<bool> signIn(String email, String password);
  Future<void> signOut();
}
