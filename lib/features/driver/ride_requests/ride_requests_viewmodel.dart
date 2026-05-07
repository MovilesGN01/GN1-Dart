import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../data/models/ride_request_model.dart';

class RideRequestsViewModel extends ChangeNotifier {
  RideRequestsViewModel({
    required this.rideId,
    required this.origin,
    required this.destination,
  }) {
    ConnectivityService().isOnline().then((online) {
      isOffline = !online;
      notifyListeners();
    });

    _connSub = ConnectivityService().onStatusChanged.listen((online) {
      final wasOffline = isOffline;
      isOffline = !online;
      notifyListeners();
      if (online && wasOffline) loadRequests();
    });
  }

  final String rideId;
  final String origin;
  final String destination;

  List<RideRequestModel> requests = [];
  bool isLoading = false;
  bool isOffline = false;

  StreamSubscription<bool>? _connSub;

  Future<void> loadRequests() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rideRequests')
          .where('rideId', isEqualTo: rideId)
          .where('status', isEqualTo: 'pending')
          .get();

      final rawRequests = snapshot.docs
          .map((doc) => RideRequestModel.fromFirestore(doc))
          .toList();

      // For any request missing a name, fetch it from the users collection
      final enriched = await Future.wait(rawRequests.map((req) async {
        if (req.passengerName != 'Unknown') return req;
        try {
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(req.passengerId)
              .get();
          final name = (userSnap.data()?['name'] as String?) ?? 'Unknown';
          final rating =
              (userSnap.data()?['reputationScore'] as num?)?.toDouble() ??
                  req.passengerRating;
          return RideRequestModel(
            id: req.id,
            rideId: req.rideId,
            passengerId: req.passengerId,
            passengerName: name,
            passengerRating: rating,
            status: req.status,
            requestTime: req.requestTime,
          );
        } catch (_) {
          return req;
        }
      }));

      requests = enriched;
    } catch (e) {
      debugPrint('[RideRequests] Firestore failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String requestId, BuildContext context) async {
    if (isOffline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot accept offline — requires live data'),
          ),
        );
      }
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await FirebaseFunctions.instance
          .httpsCallable('acceptRide')
          .call({'requestId': requestId, 'rideId': rideId});
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[RideRequests] acceptRide CF failed: $e');
      final msg = e.message ?? 'Could not accept request';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('[RideRequests] acceptRide unexpected: $e');
    } finally {
      isLoading = false;
    }

    await loadRequests();
  }

  Future<void> rejectRequest(String requestId, BuildContext context) async {
    if (isOffline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot reject offline — requires live data'),
          ),
        );
      }
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await FirebaseFunctions.instance
          .httpsCallable('rejectRide')
          .call({'requestId': requestId, 'rideId': rideId});
    } catch (e) {
      debugPrint('[RideRequests] rejectRide CF failed: $e');
    } finally {
      isLoading = false;
    }

    await loadRequests();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}
