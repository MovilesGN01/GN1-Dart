import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/booking_model.dart';
import 'viewmodels/booking_details_viewmodel.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<BookingDetailsViewModel>().load(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingDetailsViewModel>(
      builder: (context, vm, _) {
        final booking = vm.booking;

        if (vm.isLoading && booking == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.errorMessage != null && booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking details')),
            body: Center(child: Text(vm.errorMessage!)),
          );
        }

        if (booking == null) {
          return const Scaffold(
            body: Center(child: Text('No se encontró la reserva.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Booking details',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(booking: booking),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Trip information',
                icon: Icons.route_outlined,
                children: [
                  _InfoRow(label: 'Origin', value: booking.origin),
                  _InfoRow(label: 'Destination', value: booking.destination),
                  _InfoRow(
                    label: 'Departure',
                    value: _formatDateTime(booking.departureTime),
                  ),
                  _InfoRow(
                    label: 'Price',
                    value: '\$${booking.price.toStringAsFixed(0)}',
                  ),
                  _InfoRow(
                    label: 'Seats',
                    value: booking.seatsReserved.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Pickup point',
                icon: Icons.location_on_outlined,
                children: [
                  _InfoRow(
                    label: 'Selected point',
                    value: booking.selectedMeetingPoint.isEmpty
                        ? 'Not specified'
                        : booking.selectedMeetingPoint,
                  ),
                  _InfoRow(
                    label: 'Reference',
                    value: booking.pickupReference.isEmpty
                        ? 'Not specified'
                        : booking.pickupReference,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Reservation info',
                icon: Icons.event_seat_outlined,
                children: [
                  _InfoRow(label: 'Booking ID', value: booking.id),
                  _InfoRow(label: 'Ride ID', value: booking.rideId),
                  _InfoRow(label: 'Status', value: booking.status),
                  _InfoRow(
                    label: 'Created at',
                    value: _formatDateTime(booking.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F5DFF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${booking.origin} → ${booking.destination}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                booking.driverName,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StatusChip(status: booking.status),
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
    final (bg, label, fg) = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  static (Color, String, Color) _config(String status) {
    switch (status) {
      case 'confirmed':
        return (const Color(0xFFDCFCE7), 'Confirmed', const Color(0xFF166534));
      case 'pending_sync':
        return (const Color(0xFFFFF7ED), 'Pending sync', const Color(0xFFC2410C));
      case 'cancelled':
        return (const Color(0xFFFEE2E2), 'Cancelled', const Color(0xFF991B1B));
      default:
        return (const Color(0xFFFFEDD5), 'Pending', const Color(0xFFC2410C));
    }
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1F5DFF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
