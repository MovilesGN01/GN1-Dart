import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RideDetailsScreen extends StatelessWidget {
  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  final Map<String, dynamic> ride;

  static Map<String, dynamic> fallbackRide() {
    return {
      'name': 'Maria G.',
      'initial': 'M',
      'rating': 4.8,
      'from': 'Chapinero',
      'to': 'Campus',
      'time': '7:20 AM',
      'eta': '18 min',
      'price': r'$12.000',
      'seats': 2,
      'badge': 'HIGH RELIABILITY',
      'isFemaleDriver': false,
      'car': 'Mazda 2 • Gris plata',
      'plate': 'KQW 219',
      'meetingPoint': 'Cra. 13 #57-39',
      'arrivalPoint': 'Entrada peatonal ML',
      'about': 'Viaje frecuente a Uniandes. Salgo puntual y comparto ubicación en tiempo real.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = {...fallbackRide(), ...ride};
    final String? badge = data['badge'] as String?;
    final bool isFemaleDriver = (data['isFemaleDriver'] as bool?) ?? false;

    return Scaffold(
      backgroundColor: _RideDetailsColors.background,
      appBar: AppBar(
        backgroundColor: _RideDetailsColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ride details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _RideDetailsColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar('Chat con ${data['name']} disponible en la siguiente iteración.'),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  foregroundColor: _RideDetailsColors.primary,
                  side: const BorderSide(color: _RideDetailsColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _snackBar('Reserva simulada para ${data['time']} desde ${data['from']}.'),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  backgroundColor: _RideDetailsColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Reserve seat'),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DriverHeroCard(
                data: data,
                badge: badge,
                isFemaleDriver: isFemaleDriver,
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Trip summary',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.place_outlined,
                      label: 'From',
                      value: data['from'].toString(),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.flag_outlined,
                      label: 'To',
                      value: data['to'].toString(),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Departure',
                      value: '${data['time']} · ETA ${data['eta']}',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Estimated fare',
                      value: data['price'].toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Meeting points',
                child: Column(
                  children: [
                    _AddressTile(
                      title: 'Pickup',
                      address: data['meetingPoint'].toString(),
                      accent: _RideDetailsColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _AddressTile(
                      title: 'Drop-off',
                      address: data['arrivalPoint'].toString(),
                      accent: _RideDetailsColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Vehicle & driver',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle',
                      value: data['car'].toString(),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.pin_outlined,
                      label: 'Plate',
                      value: data['plate'].toString(),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.event_seat_outlined,
                      label: 'Seats available',
                      value: '${data['seats']} cupos',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'About this ride',
                child: Text(
                  data['about'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: _RideDetailsColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Safety signals',
                child: Column(
                  children: const [
                    _SafetyBullet(
                      icon: Icons.verified_user_outlined,
                      text: 'Perfil validado con correo institucional.',
                    ),
                    SizedBox(height: 10),
                    _SafetyBullet(
                      icon: Icons.star_outline_rounded,
                      text: 'Calificación alta y viaje frecuente al campus.',
                    ),
                    SizedBox(height: 10),
                    _SafetyBullet(
                      icon: Icons.location_searching_outlined,
                      text: 'Punto de encuentro y llegada definidos.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SnackBar _snackBar(String text) {
    return SnackBar(
      content: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      backgroundColor: _RideDetailsColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

abstract final class _RideDetailsColors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE5E7EB);
  static const cardSurface = Color(0xFFF8FAFC);
  static const success = Color(0xFF34C759);
  static const successLight = Color(0xFFE8F5E9);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFF3E8FF);
}

class _DriverHeroCard extends StatelessWidget {
  const _DriverHeroCard({
    required this.data,
    required this.badge,
    required this.isFemaleDriver,
  });

  final Map<String, dynamic> data;
  final String? badge;
  final bool isFemaleDriver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _RideDetailsColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RideDetailsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _RideDetailsColors.primary.withOpacity(0.12),
                child: Text(
                  data['initial'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _RideDetailsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'].toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _RideDetailsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          data['rating'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _RideDetailsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${data['seats']} cupos disponibles',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _RideDetailsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (badge != null || isFemaleDriver) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (badge != null) _Badge(label: badge!),
                if (isFemaleDriver)
                  const _Badge(
                    label: 'SAFE MATCH',
                    backgroundColor: _RideDetailsColors.purpleLight,
                    foregroundColor: _RideDetailsColors.purple,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _RideDetailsColors.border),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 10,
            color: Color(0x08000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _RideDetailsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
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
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: _RideDetailsColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _RideDetailsColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _RideDetailsColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _RideDetailsColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.title,
    required this.address,
    required this.accent,
  });

  final String title;
  final String address;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _RideDetailsColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _RideDetailsColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyBullet extends StatelessWidget {
  const _SafetyBullet({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _RideDetailsColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _RideDetailsColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bool isReliability = label.toUpperCase() == 'HIGH RELIABILITY';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isReliability ? _RideDetailsColors.successLight : _RideDetailsColors.cardSurface),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: foregroundColor ?? (isReliability ? const Color(0xFF2E7D32) : _RideDetailsColors.textPrimary),
        ),
      ),
    );
  }
}
