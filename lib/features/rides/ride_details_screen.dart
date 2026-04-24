import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'ride_details_viewmodel.dart';

class RideDetailsScreen extends StatelessWidget {
  const RideDetailsScreen({
    super.key,
    required this.rideId,
  });

  final String rideId;

  @override
  Widget build(BuildContext context) {
    return Consumer<RideDetailsViewModel>(
      builder: (context, vm, _) {
        final ride = vm.ride;

        if (vm.isLoading && ride == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (vm.errorMessage != null && ride == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Ride details'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.load(rideId),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (ride == null) {
          return const Scaffold(
            body: Center(
              child: Text('No se encontró el ride.'),
            ),
          );
        }

        final canReserve = ride.status == 'available' &&
            ride.seatsAvailable > 0 &&
            !ride.isReservedByCurrentUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            title: Text(
              'Ride details',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vm.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Text(
                      vm.errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFBE123C),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5DFF),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: canReserve && !vm.isReserving
                        ? () async {
                            final ok = await context
                                .read<RideDetailsViewModel>()
                                .reserve();

                            if (!context.mounted) return;

                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Ride reservado con éxito.'),
                                ),
                              );
                            }
                          }
                        : null,
                    child: vm.isReserving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            ride.isReservedByCurrentUser
                                ? 'Already reserved'
                                : ride.seatsAvailable <= 0
                                    ? 'No seats available'
                                    : 'Reserve seat',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => vm.load(rideId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(ride: ride),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Trip information',
                  icon: Icons.route_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Origin',
                        value: ride.origin,
                      ),
                      _InfoRow(
                        label: 'Destination',
                        value: ride.destination,
                      ),
                      _InfoRow(
                        label: 'Departure',
                        value: _formatDateTime(ride.departureTime),
                      ),
                      _InfoRow(
                        label: 'Estimated duration',
                        value: '${ride.estimatedDurationMinutes} min',
                      ),
                      _InfoRow(
                        label: 'Price',
                        value: '\$${ride.price.toStringAsFixed(0)}',
                      ),
                      _InfoRow(
                        label: 'Seats available',
                        value: '${ride.seatsAvailable}',
                      ),
                      _InfoRow(
                        label: 'Zone',
                        value: ride.zone.isEmpty ? 'Not specified' : ride.zone,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Driver',
                  icon: Icons.person_outline,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DriverAvatar(
                        name: ride.driverName,
                        photoUrl: ride.driverPhotoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driverName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ride.driverRating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                            if (ride.isFemaleDriver) ...[
                              const SizedBox(height: 8),
                              _Pill(
                                label: 'Female driver',
                                backgroundColor: const Color(0xFFFCE7F3),
                                textColor: const Color(0xFF9D174D),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Pickup point',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ride.meetingPoints.isNotEmpty) ...[
                        Text(
                          'Select one of the available pickup points:',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...ride.meetingPoints.map(
                          (point) => RadioListTile<String>(
                            value: point,
                            groupValue: ride.selectedMeetingPoint,
                            onChanged: (value) {
                              if (value != null) {
                                context.read<RideDetailsViewModel>().selectMeetingPoint(value);
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              point,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        _InfoRow(
                          label: 'Address',
                          value: ride.pickupAddress.isEmpty ? 'Not specified' : ride.pickupAddress,
                        ),
                        _InfoRow(
                          label: 'Reference',
                          value: ride.pickupReference.isEmpty ? 'Not specified' : ride.pickupReference,
                          isLast: true,
                        ),
                      ],
                    ],
                  ),
                ),
                _SectionCard(
                  title: 'Vehicle',
                  icon: Icons.directions_car_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Brand',
                        value: ride.vehicleBrand.isEmpty
                            ? 'Not specified'
                            : ride.vehicleBrand,
                      ),
                      _InfoRow(
                        label: 'Model',
                        value: ride.vehicleModel.isEmpty
                            ? 'Not specified'
                            : ride.vehicleModel,
                      ),
                      _InfoRow(
                        label: 'Color',
                        value: ride.vehicleColor.isEmpty
                            ? 'Not specified'
                            : ride.vehicleColor,
                      ),
                      _InfoRow(
                        label: 'Plate',
                        value: ride.vehiclePlate.isEmpty
                            ? 'Not specified'
                            : ride.vehiclePlate,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                if (ride.amenities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Amenities',
                    icon: Icons.check_circle_outline,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ride.amenities
                          .map(
                            (item) => _Pill(
                              label: item,
                              backgroundColor: const Color(0xFFEFF6FF),
                              textColor: const Color(0xFF1D4ED8),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (ride.badges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Badges',
                    icon: Icons.workspace_premium_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ride.badges
                          .map(
                            (item) => _Pill(
                              label: item,
                              backgroundColor: const Color(0xFFECFDF5),
                              textColor: const Color(0xFF047857),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (ride.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Driver notes',
                    icon: Icons.notes_outlined,
                    child: Text(
                      ride.notes,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.ride});

  final dynamic ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F5DFF),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F5DFF).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${ride.origin} → ${ride.destination}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  RideDetailsScreen._formatDateTime(ride.departureTime),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '\$${ride.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.event_seat_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${ride.seatsAvailable} seats',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF1F5DFF),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.name,
    required this.photoUrl,
  });

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFDCE8FF),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          color: const Color(0xFF1F5DFF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}