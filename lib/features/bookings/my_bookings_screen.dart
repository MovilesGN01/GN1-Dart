import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/bottom_nav_bar.dart';
import 'models/booking_model.dart';
import 'viewmodels/my_bookings_viewmodel.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MyBookingsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 2),
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<MyBookingsViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              if (vm.isOffline) const _OfflineBanner(),
              if (vm.isSyncing) const _SyncingBanner(),
              if (!vm.isOffline && !vm.isSyncing && vm.pendingCount > 0)
                _PendingBanner(count: vm.pendingCount),
              Expanded(child: _buildBody(vm)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(MyBookingsViewModel vm) {
    if (vm.isLoading && vm.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.bookings.isEmpty) {
      return _MessageState(
        icon: Icons.error_outline,
        title: 'Error',
        message: vm.errorMessage!,
        actionLabel: 'Reintentar',
        onPressed: vm.load,
      );
    }

    if (vm.bookings.isEmpty) {
      return const _MessageState(
        icon: Icons.event_seat_outlined,
        title: 'No tienes reservas',
        message: 'Cuando reserves un ride, aparecerá aquí.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: vm.bookings.length,
        itemBuilder: (context, index) =>
            _BookingCard(booking: vm.bookings[index]),
      ),
    );
  }
}

// ── Banners ───────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión — mostrando datos en caché',
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

class _SyncingBanner extends StatelessWidget {
  const _SyncingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Sincronizando reservas pendientes…',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF7ED),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: Color(0xFFC2410C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count reserva${count > 1 ? 's' : ''} pendiente${count > 1 ? 's' : ''} de sincronizar',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFC2410C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: booking.isLocalOnly
          ? null
          : () => context.push('/bookings/${booking.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: booking.isLocalOnly
                ? const Color(0xFFFED7AA)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFDCE8FF),
                  child: Text(
                    booking.driverName.isNotEmpty
                        ? booking.driverName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1F5DFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.driverName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                _StatusPill(status: booking.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${booking.origin} → ${booking.destination}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(booking.departureTime),
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '\$${booking.price.toStringAsFixed(0)} · ${booking.seatsReserved} seat',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1F5DFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (booking.isLocalOnly) ...[
                  const SizedBox(width: 8),
                  Text(
                    '· Sin conexión',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFC2410C),
                      fontSize: 12,
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

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$day/$month/${value.year} · $hour:$minute $period';
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cfg = _pillConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cfg.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        cfg.$2,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cfg.$3,
        ),
      ),
    );
  }

  static (Color, String, Color) _pillConfig(String status) {
    switch (status) {
      case 'confirmed':
        return (
          const Color(0xFFDCFCE7),
          'Confirmed',
          const Color(0xFF166534),
        );
      case 'pending_sync':
        return (
          const Color(0xFFFFF7ED),
          'Pending sync',
          const Color(0xFFC2410C),
        );
      case 'cancelled':
        return (
          const Color(0xFFFEE2E2),
          'Cancelled',
          const Color(0xFF991B1B),
        );
      default:
        return (
          const Color(0xFFFFEDD5),
          'Pending',
          const Color(0xFFC2410C),
        );
    }
  }
}

// ── Empty / error state ───────────────────────────────────────────────────────

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
