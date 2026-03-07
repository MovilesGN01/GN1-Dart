import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

// ── Local colour palette ──────────────────────────────────────────────────────
abstract final class _RidesColors {
  static const primary       = Color(0xFF1F5DFF);
  static const background    = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted         = Color(0xFF94A3B8);
  static const cardSurface   = Color(0xFFF8FAFC);
  static const border        = Color(0xFFE5E7EB);
  static const urgent        = Color(0xFFFF3B30);
  static const success       = Color(0xFF34C759);
  static const successLight  = Color(0xFFE8F5E9);
  static const successText   = Color(0xFF2E7D32);
  static const purple        = Color(0xFF7C3AED);
  static const purpleLight   = Color(0xFFF3E8FF);
  static const purpleText    = Color(0xFF6D28D9);
  static const warningAmber  = Color(0xFFF59E0B);
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  String _selectedDeparture = 'Now';
  String _activeFilter = 'High Reliability';

  final List<Map<String, dynamic>> _rides = [
    {
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
    },
    {
      'name': 'Andrés R.',
      'initial': 'A',
      'rating': 4.6,
      'from': 'Teusaquillo',
      'to': 'Campus',
      'time': '7:35 AM',
      'eta': '25 min',
      'price': r'$10.000',
      'seats': 1,
      'badge': null,
      'isFemaleDriver': false,
    },
    {
      'name': 'Camila P.',
      'initial': 'C',
      'rating': 4.9,
      'from': 'Salitre',
      'to': 'Campus',
      'time': '7:50 AM',
      'eta': '30 min',
      'price': r'$14.000',
      'seats': 3,
      'badge': 'FEMALE DRIVER',
      'isFemaleDriver': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RidesColors.background,
      appBar: AppBar(
        backgroundColor: _RidesColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _RidesColors.textPrimary,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Rides',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _RidesColors.textPrimary,
              ),
            ),
            Text(
              'Chapinero → Campus',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _RidesColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: _RidesColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search summary
              _SearchSummaryCard(),

              // Filter chips
              _FilterChipsRow(
                activeFilter: _activeFilter,
                onFilterChanged: (val) => setState(() => _activeFilter = val),
              ),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'RECOMMENDED RIDES',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _RidesColors.muted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Ride cards
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _rides.length,
                itemBuilder: (_, i) => _RideCard(ride: _rides[i]),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SearchSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _RidesColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _RidesColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FROM / TO row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _RidesColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _RidesColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chapinero',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _RidesColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  color: _RidesColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _RidesColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: _RidesColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Campus',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _RidesColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Departure row
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 14,
                color: _RidesColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                'Departure:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _RidesColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDeparture,
                    isDense: true,
                    isExpanded: true,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _RidesColors.textPrimary,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: _RidesColors.muted,
                    ),
                    items: ['Now', '7:00 AM', '7:30 AM', '8:00 AM', '8:30 AM']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDeparture = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _RidesColors.primary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Search',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  static const _filters = ['High Reliability', 'Female Driver', '4.5+ Rating'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _filters
            .map(
              (label) => _FilterChip(
                label: label,
                isSelected: label == activeFilter,
                onTap: () => onFilterChanged(label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _RidesColors.primary : _RidesColors.background,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: _RidesColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? _RidesColors.background
                : _RidesColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride});

  final Map<String, dynamic> ride;

  @override
  Widget build(BuildContext context) {
    final String? badge = ride['badge'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _RidesColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RidesColors.border),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 8,
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ROW 1 — driver info + badge
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _RidesColors.primary,
                child: Text(
                  ride['initial'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _RidesColors.background,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ride['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _RidesColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: _RidesColors.warningAmber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (ride['rating'] as double).toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _RidesColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (badge != null) _DriverBadge(badge: badge),
            ],
          ),
          const SizedBox(height: 12),

          // ROW 2 — route + time
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _RidesColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ride['from'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _RidesColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 1,
                      height: 14,
                      color: _RidesColors.border,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: _RidesColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ride['to'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _RidesColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ride['time'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _RidesColors.primary,
                    ),
                  ),
                  Text(
                    'ETA ${ride['eta']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _RidesColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _RidesColors.border, height: 1),
          const SizedBox(height: 12),

          // ROW 3 — price + seats + reserve button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ride['price'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _RidesColors.textPrimary,
                      ),
                    ),
                    if ((ride['seats'] as int) == 1)
                      Text(
                        'Only 1 seat left!',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _RidesColors.urgent,
                        ),
                      )
                    else
                      Text(
                        '${ride['seats']} seats left',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _RidesColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ride reserved with ${ride['name']}!',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: _RidesColors.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _RidesColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Reserve',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverBadge extends StatelessWidget {
  const _DriverBadge({required this.badge});

  final String badge;

  @override
  Widget build(BuildContext context) {
    final bool isReliability = badge == 'HIGH RELIABILITY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReliability
            ? _RidesColors.successLight
            : _RidesColors.purpleLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badge,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: isReliability
              ? _RidesColors.successText
              : _RidesColors.purpleText,
        ),
      ),
    );
  }
}
