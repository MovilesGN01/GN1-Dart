import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../../shared/widgets/offline_banner.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  bool _isOffline = false;
  bool _isLoading = false;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<DocumentSnapshot>? _rideSub;

  @override
  void initState() {
    super.initState();
    ConnectivityService().isOnline().then((online) {
      if (mounted) setState(() => _isOffline = !online);
    });
    _connSub = ConnectivityService().onStatusChanged.listen((online) {
      if (mounted) setState(() => _isOffline = !online);
    });

    // Watch the ride document — if it becomes completed/cancelled externally,
    // navigate home automatically.
    _rideSub = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final status = (snap.data()?['status'] as String?) ?? '';
      if (status == 'completed' || status == 'cancelled') {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _rideSub?.cancel();
    super.dispose();
  }

  Future<void> _finishRide() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('finishRide')
          .call({'rideId': widget.rideId});
      // Navigation is handled by _rideSub reacting to status → completed
    } catch (e) {
      debugPrint('[ActiveRide] finishRide error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo finalizar el viaje. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Active Ride',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineBanner(isOffline: _isOffline, isFromCache: false),

          // Map placeholder
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Map coming soon',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Passengers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rideRequests')
                  .where('rideId', isEqualTo: widget.rideId)
                  .where('status', isEqualTo: 'accepted')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No passengers yet'),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final name =
                        (data['passengerName'] as String?) ?? 'Passenger';
                    final rating =
                        (data['rating'] as num?)?.toStringAsFixed(1) ?? '–';
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(name.isNotEmpty ? name[0] : '?'),
                      ),
                      title: Text(name),
                      subtitle: Text('Rating: $rating'),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_isOffline || _isLoading) ? null : _finishRide,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Finish Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
