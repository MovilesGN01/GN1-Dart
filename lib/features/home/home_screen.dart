import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';
import 'package:uniride/shared/widgets/location_disabled_banner.dart';

import '../../core/location_utils.dart';
import '../../data/models/ride_model.dart';
import '../../features/auth/auth_viewmodel.dart';
import '../../features/home/weather_viewmodel.dart';
import '../../features/rides/ride_viewmodel.dart';
import '../chatbot/presentation/chatbot_sheet.dart';

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
  static const badgeBg       = Color(0xFFE8F5E9);
  static const badgeText     = Color(0xFF2E7D32);
}

// ── Display model (for carousel cards) ──────────────────────────────────────
class _RideData {
  const _RideData({
    required this.name,
    required this.time,
    required this.price,
    required this.rating,
    required this.seats,
    this.badge,
  });

  final String name;
  final String time;
  final String price;
  final String rating;
  final String seats;
  final String? badge;

  factory _RideData.fromModel(RideModel r) {
    return _RideData(
      name: r.driverName,
      time: _fmtTime(r.departureTime),
      price: _fmtPrice(r.price),
      rating: r.driverRating.toStringAsFixed(1),
      seats: '${r.seatsAvailable} cupos',
      badge: r.driverRating >= 4.8 ? 'High Reliability' : null,
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  static String _fmtPrice(double p) {
    final n = p.toInt();
    if (n >= 1000) {
      return '\$${n ~/ 1000}.${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '\$$n';
  }
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
    context.read<RideViewModel>().loadAvailableRides();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherViewModel>().loadWeather();
      context.read<AuthViewModel>().loadRecurringRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideVm = context.watch<RideViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final weatherVm = context.watch<WeatherViewModel>();

    final String firstName = authVm.currentUser?.name.split(' ').first ?? 'there';
    final String initial = authVm.currentUser?.name.isNotEmpty == true
        ? authVm.currentUser!.name[0].toUpperCase()
        : '?';

    final List<_RideData> displayRides =
        rideVm.rides.map(_RideData.fromModel).toList();

    return Scaffold(
      backgroundColor: _HomeColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _HomeColors.primary,
        tooltip: 'Asistente UniRide',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ChatbotSheet(),
          );
        },
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
              _HomeHeader(firstName: firstName, initial: initial),
              const SizedBox(height: 8),

              if (_showWeatherBanner &&
                  (weatherVm.weather?.willRainSoon ?? false) &&
                  !rideVm.isLoading &&
                  rideVm.rides.isNotEmpty) ...[
                _WeatherBanner(
                  onDismiss: () => setState(() => _showWeatherBanner = false),
                ),
                const SizedBox(height: 8),
              ],

              const _SearchCard(),
              const SizedBox(height: 16),

              const _ExploreAlternatives(),
              const SizedBox(height: 16),

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

              if (rideVm.isLoading)
                const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (rideVm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    rideVm.errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                )
              else if (displayRides.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No rides available right now.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _HomeColors.muted,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayRides.length,
                    itemBuilder: (_, i) => _RideCard(ride: displayRides[i]),
                  ),
                ),

              const SizedBox(height: 16),
              _RecurringRidesSection(routes: authVm.recurringRoutes),
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
  const _HomeHeader({required this.firstName, required this.initial});

  final String firstName;
  final String initial;

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
              initial,
              style: GoogleFonts.poppins(
                color: _HomeColors.background,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                  firstName,
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
                    Flexible(
                      child: Text(
                        'Uniandes · Verified Student',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _HomeColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    final prob = context.watch<WeatherViewModel>()
            .weather
            ?.precipitationProbability ??
        0;
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
                  '🌧 Rain expected in the next 2 days — $prob% chance.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _HomeColors.textPrimary,
                  ),
                ),
                Text(
                  'Book a high-rated ride now.',
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
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  String _selectedTime = 'Now';
  bool _gpsAutoFilled = false;
  bool _locationServiceDisabled = false;
  StreamSubscription<ServiceStatus>? _locationServiceStream;

  static const _timeOptions = ['Now', 'In 30 min', 'In 1 hour', 'In 2 hours'];

  @override
  void initState() {
    super.initState();
    _fromController.addListener(_onFromChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _tryAutoFillLocation();
      _locationServiceStream = Geolocator.getServiceStatusStream().listen(
        (ServiceStatus status) {
          if (!mounted) return;
          if (status == ServiceStatus.enabled) {
            setState(() => _locationServiceDisabled = false);
            _tryAutoFillLocation();
          } else {
            setState(() => _locationServiceDisabled = true);
          }
        },
      );
    });
  }

  void _onFromChanged() {
    if (_gpsAutoFilled) setState(() => _gpsAutoFilled = false);
  }

  Future<void> _tryAutoFillLocation() async {
    if (_fromController.text.isNotEmpty) return;
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationServiceDisabled = true);
      return;
    }
    if (mounted) setState(() => _locationServiceDisabled = false);
    final zone = await LocationUtils.detectZone();
    if (zone != null && mounted && _fromController.text.isEmpty) {
      _fromController.text = zone;
      setState(() => _gpsAutoFilled = true);
    }
  }

  @override
  void dispose() {
    _locationServiceStream?.cancel();
    _fromController.removeListener(_onFromChanged);
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, IconData icon, double iconSize) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: iconSize, color: _HomeColors.primary),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: _HomeColors.muted),
      filled: true,
      fillColor: _HomeColors.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _HomeColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _HomeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _HomeColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_locationServiceDisabled) const LocationDisabledBanner(),
        _buildCard(context),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
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
          TextField(
            controller: _fromController,
            style: GoogleFonts.poppins(fontSize: 14, color: _HomeColors.textPrimary),
            decoration: _fieldDecoration('Enter origin', Icons.circle, 10),
          ),
          if (_gpsAutoFilled) ...[
            const SizedBox(height: 3),
            Text(
              '📍 Detected automatically — tap to edit',
              style: GoogleFonts.poppins(fontSize: 10, color: _HomeColors.muted),
            ),
          ],
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
          TextField(
            controller: _toController,
            style: GoogleFonts.poppins(fontSize: 14, color: _HomeColors.textPrimary),
            decoration: _fieldDecoration('Enter destination', Icons.location_on, 16),
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
              onPressed: () {
                final from = Uri.encodeComponent(_fromController.text.trim());
                final to = Uri.encodeComponent(_toController.text.trim());
                final dep = Uri.encodeComponent(_selectedTime);
                context.go('/rides?from=$from&to=$to&departure=$dep');
              },
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


class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride});

  final _RideData ride;

  @override
  Widget build(BuildContext context) {
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
                  ride.name[0],
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
                  ride.name,
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
            ride.time,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _HomeColors.primary,
            ),
          ),
          Text(
            ride.price,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _HomeColors.textPrimary,
            ),
          ),
          Text(
            ride.seats,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _HomeColors.muted,
            ),
          ),
          if (ride.badge != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _HomeColors.badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ride.badge!,
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
  const _RecurringRidesSection({required this.routes});

  final List<Map<String, dynamic>> routes;

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
        if (routes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No recurring rides yet.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _HomeColors.muted,
              ),
            ),
          )
        else
          ...routes.asMap().entries.map((entry) {
            final i = entry.key;
            final route = entry.value;
            final origin = route['origin'] as String? ?? '';
            final destination = route['destination'] as String? ?? 'Campus Uniandes';
            final count = route['count'] as int? ?? 0;
            return Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: _HomeColors.weatherBg,
                    child: Icon(Icons.route, color: _HomeColors.primary),
                  ),
                  title: Text(
                    '$origin → $destination',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _HomeColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Used $count times this month',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _HomeColors.muted),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: _HomeColors.muted,
                  ),
                ),
                if (i < routes.length - 1)
                  const Divider(
                    color: _HomeColors.border,
                    thickness: 1,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
      ],
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip();

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherViewModel>().weather;

    if (weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Text('--', style: TextStyle(fontSize: 11)),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.temperature.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  weather.description,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF555555),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
