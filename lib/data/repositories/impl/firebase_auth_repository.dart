import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../user_repository.dart';
import '../../models/user_model.dart';

class FirebaseAuthRepository implements UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> signIn(String email, String password) async {
    if (!email.endsWith('@uniandes.edu.co')) {
      throw Exception('Only @uniandes.edu.co email addresses are allowed.');
    }
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      final String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Please use your @uniandes.edu.co email.';
          break;
        default:
          message = e.message ?? 'Authentication failed.';
      }
      throw Exception(message);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  @override
  Future<int> getQueuePosition(String userId, String rideId) async {
    final userDoc =
        await _firestore.collection('users').doc(userId).get();
    final userScore =
        (userDoc.data()?['reputationScore'] as num?)?.toDouble() ?? 0.0;

    final snapshot = await _firestore
        .collection('rides')
        .doc(rideId)
        .collection('queue')
        .where('reputationScore', isGreaterThan: userScore)
        .get();

    return snapshot.docs.length + 1;
  }

  @override
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String vehiclePlate,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createUserDocument');
      await callable.call({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        if (vehiclePlate.isNotEmpty) 'vehiclePlate': vehiclePlate,
      });
    } catch (e) {
      await credential.user!.delete();
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecurringRoutes(String userId) async {
    final snapshot = await _firestore
        .collection('rideHistory')
        .where('passengerId', isEqualTo: userId)
        .get();

    final Map<String, Map<String, dynamic>> grouped = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final origin = data['origin'] as String? ?? '';
      final destination =
          data['destination'] as String? ?? 'Campus Uniandes';
      if (origin.isEmpty) continue;
      if (grouped.containsKey(origin)) {
        grouped[origin]!['count'] =
            (grouped[origin]!['count'] as int) + 1;
      } else {
        grouped[origin] = {
          'origin': origin,
          'destination': destination,
          'count': 1,
        };
      }
    }

    final sorted = grouped.values.toList()
      ..sort((a, b) =>
          (b['count'] as int).compareTo(a['count'] as int));

    return sorted.take(2).toList();
  }
}
