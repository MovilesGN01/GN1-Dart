import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uniride/data/models/ride_model.dart';
import 'package:uniride/presentation/viewmodels/ride_viewmodel.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

// ── Local colour palette ─────────────────────────────────────────────────────
abstract final class _HomeColors {
  static const primary       = Color(0xFF1F5DFF);
  static const background    = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted         = Color(0xFF94A3B8);
  static const cardSurface   = Color(0xFFF8FAFC);
  static const border        = Color(0xFFE5E7EB);
  static const weatherBg     = Color(0xFFEFF6FF);
  static const amber         = Color(0xFFF59E0B);
  static const badgeBg       = Color(0xFFE8F5E9);
  static const badgeText     = Color(0xFF2E7D32);
}

// ── Display helpers ───────────────────────────────────────────────────────────
String _formatDepartureTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _formatPrice(double price) {
  return '\$${(price / 1000).toStringAsFixed(0)}.000';
}

String _formatSeats(int seats) {
  return '$seats cupo${seats == 1 ? '' : 's'}';
}

String? _getBadge(RideModel ride) {
  if (ride.isFemaleDriver) return 'Female Driver';
  if (ride.reputationScore >= 4.8) return 'High Reliability';
  return null;
}

// ── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWeatherBanner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RideViewModel>();
      if (vm.rides.isEmpty && !vm.isLoading) {
        vm.loadRides();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideVm = context.watch<RideViewModel>();

    return Scaffold(
      backgroundColor: _HomeColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _HomeColors.primary,
        tooltip: 'Asistente UniRide',
        onPressed: null,
        child: const Icon(
          Icons.smart_toy_outlined,
          color: _HomeColors.background,
        ),
      ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const _HomeHeader(),
              const SizedBox(height: 8),

              // Weather banner (conditional)
              if (_showWeatherBanner) ...[
                _WeatherBanner(
                  onDismiss: () =>
                      setState(() => _showWeatherBanner = false),
                ),
                const SizedBox(height: 8),
              ],

              // Search card
              const _SearchCard(),
              const SizedBox(height: 16),

              // Explore alternatives
              const _ExploreAlternatives(),
              const SizedBox(height: 16),

              // Available rides
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Available Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _HomeColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: rideVm.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _HomeColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rideVm.rides.take(3).length,
                        itemBuilder: (_, i) =>
                            _RideCard(ride: rideVm.rides[i]),
                      ),
              ),
              const SizedBox(height: 16),

              // Recurring rides
              const _RecurringRidesSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _HomeColors.primary,
            child: Text(
              'F',
              style: GoogleFonts.poppins(
                color: _HomeColors.background,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _HomeColors.textSecondary,
                  ),
                ),
                Text(
                  'Felipe',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _HomeColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: _HomeColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Uniandes · Verified Student',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _HomeColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _WeatherChip(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: _HomeColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomeColors.weatherBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.water_drop, color: _HomeColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rain tomorrow 7–9 AM',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _HomeColors.textPrimary,
                  ),
                ),
                Text(
                  'High demand expected · 3 drivers available',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _HomeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/rides'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Reserve →',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _HomeColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: _HomeColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatefulWidget {
  const _SearchCard();

  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard> {
  String _selectedTime = 'Now';
  static const _timeOptions = [
    'Now',
    '7:00 AM',
    '7:30 AM',
    '8:00 AM',
    '8:30 AM',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomeColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Your Commute',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _HomeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // FROM
          const _SearchField(
            icon: Icons.circle,
            iconSize: 10,
            label: '  From: Chapinero',
          ),
          const SizedBox(height: 8),

          // Connector
          Container(
            width: 1,
            height: 16,
            color: _HomeColors.border,
            margin: const EdgeInsets.only(left: 16),
          ),
          const SizedBox(height: 8),

          // TO
          const _SearchField(
            icon: Icons.location_on,
            iconSize: 16,
            label: '  To: Campus Uniandes',
          ),
          const SizedBox(height: 8),

          // Departure time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _HomeColors.background,
              border: Border.all(color: _HomeColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: _HomeColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Departure',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _HomeColors.muted,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedTime,
                  items: _timeOptions
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ),
                      )
                      .toList(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _HomeColors.textPrimary,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: _HomeColors.muted,
                  ),
                  onChanged: (val) => setState(() => _selectedTime = val!),
                  underline: const SizedBox(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/rides'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _HomeColors.primary,
                foregroundColor: _HomeColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Start Search'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.icon,
    required this.iconSize,
    required this.label,
  });

  final IconData icon;
  final double iconSize;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _HomeColors.background,
        border: Border.all(color: _HomeColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: _HomeColors.primary),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _HomeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final badge = _getBadge(ride);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _HomeColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _HomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _HomeColors.primary,
                child: Text(
                  ride.driverName[0],
                  style: GoogleFonts.poppins(
                    color: _HomeColors.background,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.driverName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _HomeColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDepartureTime(ride.departureTime),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _HomeColors.primary,
            ),
          ),
          Text(
            _formatPrice(ride.price),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _HomeColors.textPrimary,
            ),
          ),
          Text(
            _formatSeats(ride.seatsAvailable),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _HomeColors.muted,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _HomeColors.badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: _HomeColors.badgeText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringRidesSection extends StatelessWidget {
  const _RecurringRidesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Recurring Rides',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _HomeColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _HomeColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: _HomeColors.weatherBg,
            child: Icon(Icons.home_outlined, color: _HomeColors.primary),
          ),
          title: Text(
            'Home → Campus',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _HomeColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Mon, Wed, Fri · 08:30 AM',
            style: GoogleFonts.poppins(fontSize: 12, color: _HomeColors.muted),
          ),
        ),
        const Divider(
          color: _HomeColors.border,
          thickness: 1,
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: _HomeColors.weatherBg,
            child: Icon(Icons.school_outlined, color: _HomeColors.primary),
          ),
          title: Text(
            'Work → Campus',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _HomeColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Daily · 05:45 PM',
            style: GoogleFonts.poppins(fontSize: 12, color: _HomeColors.muted),
          ),
        ),
      ],
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _HomeColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HomeColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            size: 16,
            color: _HomeColors.amber,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '18°C',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _HomeColors.textPrimary,
                ),
              ),
              Text(
                'Sunny',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: _HomeColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreAlternatives extends StatelessWidget {
  const _ExploreAlternatives();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Explore Alternatives',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _HomeColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _AlternativeCard(
                icon: Icons.directions_car,
                title: 'Carpool',
                subtitle: 'Split fare with\nstudents',
                tooltip: 'Filter by shared fare rides',
                onPressed: () => context.go('/rides'),
              ),
              _AlternativeCard(
                icon: Icons.directions_bus,
                title: 'University Bus',
                subtitle: 'Official campus\nbus routes',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coming soon',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: _HomeColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              _AlternativeCard(
                icon: Icons.directions_walk,
                title: 'Walk & Transit',
                subtitle: 'TransMilenio\n& walking',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coming soon',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: _HomeColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomeColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: _HomeColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _HomeColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _HomeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: Tooltip(
              message: tooltip ?? '',
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HomeColors.primary,
                  foregroundColor: _HomeColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('VIEW OPTION'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
