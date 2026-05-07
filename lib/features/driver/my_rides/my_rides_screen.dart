import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/models/ride_model.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import 'my_rides_viewmodel.dart';

// ── Colour palette ────────────────────────────────────────────────────────────
abstract final class _Colors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE5E7EB);
  static const green = Color(0xFF16A34A);
  static const blue = Color(0xFF2563EB);
  static const orange = Color(0xFFF97316);
  static const grey = Color(0xFF9CA3AF);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEF2F2);
  static const redBorder = Color(0xFFFCA5A5);
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _fmtTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $p';
}

String _fmtPrice(double p) {
  final n = p.toInt();
  if (n >= 1000) {
    return '\$${n ~/ 1000}.${(n % 1000).toString().padLeft(3, '0')}';
  }
  return '\$$n';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && mounted) {
        context.read<MyRidesViewModel>().loadRides(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRidesViewModel>();

    return Scaffold(
      backgroundColor: _Colors.background,
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: _Colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Rides',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _Colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _Colors.primary),
            onPressed: () => context.push('/driver/create-ride'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            OfflineBanner(
              isOffline: vm.isOffline,
              isFromCache: vm.isFromCache,
            ),
            Expanded(
              child: _buildBody(vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(MyRidesViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: _Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No rides published yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: _Colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.push('/driver/create-ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create your first ride',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: vm.rides.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RideDriverCard(ride: vm.rides[i]),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────
class _RideDriverCard extends StatelessWidget {
  const _RideDriverCard({required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final isPending = ride.status == 'pending';
    final canNavigate = !isPending;
    final showActiveRide =
        ride.status == 'available' || ride.status == 'in_progress';
    final now = DateTime.now();
    final isOverdue = (ride.status == 'available' || ride.status == 'active') &&
        ride.departureTime.isBefore(now);

    return GestureDetector(
      onTap: () async {
        final result = await context.push<bool>(
          '/driver/my-rides/${ride.id}',
          extra: ride,
        );
        if ((result ?? false) && context.mounted) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            context.read<MyRidesViewModel>().loadRides(uid);
          }
        }
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? _Colors.redLight : _Colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? _Colors.redBorder : _Colors.border,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0A000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _Colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.origin,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14, color: _Colors.muted),
              ),
              Expanded(
                child: Text(
                  ride.destination,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details row
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 13, color: _Colors.muted),
              const SizedBox(width: 4),
              Text(
                _fmtTime(ride.departureTime),
                style: GoogleFonts.poppins(fontSize: 12, color: _Colors.textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.event_seat_outlined, size: 13, color: _Colors.muted),
              const SizedBox(width: 4),
              Text(
                '${ride.seatsAvailable} seats',
                style: GoogleFonts.poppins(fontSize: 12, color: _Colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                _fmtPrice(ride.price),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status row
          Row(
            children: [
              _StatusChip(status: ride.status, isOverdue: isOverdue),
            ],
          ),

          if (isOverdue) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: _Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '¡Hora de salida pasada! Inicia el viaje o se cancelará automáticamente.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isPending) ...[
            const SizedBox(height: 6),
            Text(
              'Will publish when reconnected',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _Colors.orange,
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: _Colors.border, height: 1),
          const SizedBox(height: 12),

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canNavigate
                      ? () => context.push(
                            '/driver/ride-requests',
                            extra: {
                              'rideId': ride.id,
                              'origin': ride.origin,
                              'destination': ride.destination,
                            },
                          )
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: canNavigate ? _Colors.primary : _Colors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'View Requests',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: canNavigate ? _Colors.primary : _Colors.muted,
                    ),
                  ),
                ),
              ),
              if (showActiveRide) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => context.push(
                      '/driver/active-ride',
                      extra: {'rideId': ride.id},
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Active Ride →',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.isOverdue = false});

  final String status;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 11, color: _Colors.red),
            const SizedBox(width: 3),
            Text(
              '¡Iniciar ya!',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case 'available':
        bg = const Color(0xFFDCFCE7);
        fg = _Colors.green;
        label = 'Available';
      case 'in_progress':
        bg = const Color(0xFFDBEAFE);
        fg = _Colors.blue;
        label = 'In Progress';
      case 'completed':
        bg = const Color(0xFFF3F4F6);
        fg = _Colors.grey;
        label = 'Completed';
      default: // 'pending'
        bg = const Color(0xFFFED7AA);
        fg = _Colors.orange;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
