import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NfcVerificationService {
  NfcVerificationService()
      : _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<bool> verifyTag(
    String tagId, {
    String? rideId,
    String? userId,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;

    final callable = _functions.httpsCallable('verifyNFC');

    try {
      final result = await callable.call(<String, dynamic>{
        'nfcId': tagId,
        'rideId': ?rideId,
        'userId': ?uid,
      });

      final data = result.data;
      if (data is Map && data['success'] == true) {
        return true;
      }
      return false;
    } on FirebaseFunctionsException catch (e) {
      // verifyNFC throws "Invalid NFC" when the tag is not registered/active.
      if (e.message?.toLowerCase().contains('invalid nfc') ?? false) {
        return false;
      }
      rethrow;
    }
  }
}
