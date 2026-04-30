import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/ride_status_model.dart';
import '../../data/repositories/impl/firebase_ride_repository.dart';
import '../../shared/widgets/offline_banner.dart';
import '../bookings/data/booking_repository.dart';
import '../rating/rate_ride_sheet.dart';
import '../rating/rate_ride_viewmodel.dart';
import 'active_ride_viewmodel.dart';

abstract final class _Colors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const cardSurface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const emergency = Color(0xFFDC2626);
  static const statusBg = Color(0xFFEFF6FF);
  static const completedBg = Color(0xFFDCFCE7);
  static const completedText = Color(0xFF166534);
}

class ActiveRideScreen extends StatelessWidget {
  const ActiveRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.background,
      appBar: AppBar(
        title: Text(
          'Active Ride',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _Colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<ActiveRideViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              OfflineBanner(
                isOffline: vm.isOffline,
                isFromCache: false,
                messageOverride: 'Live updates paused — reconnecting...',
              ),
              Expanded(
                child: vm.currentStatus == null
                    ? const Center(child: CircularProgressIndicator())
                    : _RideBody(vm: vm),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RideBody extends StatelessWidget {
  const _RideBody({required this.vm});

  final ActiveRideViewModel vm;

  @override
  Widget build(BuildContext context) {
    final status = vm.currentStatus!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusChip(status: status.status),
          const SizedBox(height: 16),
          _DriverCard(status: status),
          const SizedBox(height: 12),
          _RouteCard(status: status),
          const SizedBox(height: 12),
          _DetailsCard(status: status),
          if (vm.isOffline) ...[
            const SizedBox(height: 12),
            _FrozenBanner(),
          ],
          const SizedBox(height: 24),
          if (vm.isCompleted) ...[
            _RateButton(
              rideId: status.rideId,
              driverName: status.driverName,
              driverId: status.driverId,
            ),
            const SizedBox(height: 12),
          ],
          _EmergencyButton(),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = RideStatusModel.isActiveStatus(status);
    final isCompleted = RideStatusModel.isCompletedStatus(status);

    final Color bg;
    final Color textColor;
    final String label;

    if (isCompleted) {
      bg = _Colors.completedBg;
      textColor = _Colors.completedText;
      label = 'Ride Completed';
    } else if (isActive) {
      bg = _Colors.statusBg;
      textColor = _Colors.primary;
      label = 'Driver en route';
    } else {
      bg = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFC2410C);
      label = status.isNotEmpty ? status : 'Loading...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _Colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.status});

  final RideStatusModel status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _Colors.primary,
            child: Text(
              status.driverName.isNotEmpty
                  ? status.driverName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.driverName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _Colors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      status.driverRating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _Colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (status.vehiclePlate.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _Colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _Colors.border),
              ),
              child: Text(
                status.vehiclePlate,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Colors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.status});

  final RideStatusModel status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteRow(
            icon: Icons.circle,
            iconColor: _Colors.primary,
            iconSize: 10,
            label: status.origin,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Container(
              width: 1,
              height: 20,
              color: _Colors.border,
            ),
          ),
          _RouteRow(
            icon: Icons.location_on,
            iconColor: _Colors.primary,
            iconSize: 18,
            label: status.destination,
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label.isNotEmpty ? label : '—',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _Colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.status});

  final RideStatusModel status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        children: [
          if (status.selectedMeetingPoint.isNotEmpty)
            _DetailRow(
              icon: Icons.place_outlined,
              label: 'Meeting point',
              value: status.selectedMeetingPoint,
            ),
          if (status.pickupReference.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.info_outline,
              label: 'Pickup reference',
              value: status.pickupReference,
            ),
          ],
          if (status.vehicleModel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle',
              value: [
                status.vehicleColor,
                status.vehicleBrand,
                status.vehicleModel,
              ].where((s) => s.isNotEmpty).join(' '),
            ),
          ],
          if (status.departureTime != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.access_time_outlined,
              label: 'Departure',
              value: _fmtTime(status.departureTime!),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _Colors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _Colors.muted,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _Colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FrozenBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline,
              size: 16, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Live updates paused — reconnecting...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.rideId,
    required this.driverName,
    required this.driverId,
  });

  final String rideId;
  final String driverName;
  final String driverId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.star_outline),
        label: Text(
          'Rate this ride',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _Colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () => _openRateSheet(context),
      ),
    );
  }

  void _openRateSheet(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => RateRideViewModel(
          FirebaseRideRepository(),
          BookingRepository(),
        ),
        child: RateRideSheet(
          rideId: rideId,
          driverId: driverId,
          driverName: driverName,
          userId: userId,
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.warning_amber_rounded, color: _Colors.emergency),
        label: Text(
          'Emergency',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Colors.emergency,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _Colors.emergency),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _showEmergencyDialog(context),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: _Colors.emergency),
            const SizedBox(width: 8),
            Text(
              'Emergency',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you are in immediate danger, contact:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _EmergencyContactRow(
                label: 'Police / Emergency', number: '123'),
            const SizedBox(height: 8),
            _EmergencyContactRow(
                label: 'Campus Security', number: '601 332 4344'),
            const SizedBox(height: 8),
            _EmergencyContactRow(
                label: 'UniRide Support', number: '601 339 4949'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: _Colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactRow extends StatelessWidget {
  const _EmergencyContactRow(
      {required this.label, required this.number});

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
        ),
        Text(
          number,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _Colors.emergency,
          ),
        ),
      ],
    );
  }
}
