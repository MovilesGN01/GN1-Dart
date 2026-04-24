import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

import '../../core/location_utils.dart';
import '../../data/models/ride_model.dart';
import '../../features/rides/ride_viewmodel.dart';
import '../../shared/widgets/location_disabled_banner.dart';

// ── Local colour palette ──────────────────────────────────────────────────────
abstract final class _RidesColors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const cardSurface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const urgent = Color(0xFFFF3B30);
  static const warningAmber = Color(0xFFF59E0B);
  static const rainBg = Color(0xFFDBEAFE);
  static const rainText = Color(0xFF1E3A8A);
  static const bestMatchBg = Color(0xFFFEF9C3);
  static const bestMatchText = Color(0xFF92400E);
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


double _rankScore(RideModel r) =>
    (r.driverRating * 0.5) +
    (r.punctualityRate * 0.3) +
    (r.seatsAvailable * 0.2);


// ── Screen ────────────────────────────────────────────────────────────────────
class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  String _selectedDeparture = 'Now';
  bool _gpsAutoFilled = false;
  bool _locationServiceDisabled = false;
  bool _ignoreNextFromChange = false;
  StreamSubscription<ServiceStatus>? _locationServiceStream;
  String _activeFilter = 'All';
  List<RideModel> _filteredRides = [];
  bool _hasSearched = false;
  bool _pendingAutoSearch = false;

  static const _departureOptions = ['Now', 'In 30 min', 'In 1 hour', 'In 2 hours'];

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController();
    _toController = TextEditingController();
    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-fill FROM/TO from query parameters passed by home screen
      final params = GoRouterState.of(context).uri.queryParameters;
      final from = params['from'] ?? '';
      final to = params['to'] ?? '';
      final departure = params['departure'] ?? '';
      if (from.isNotEmpty) _fromController.text = from;
      if (to.isNotEmpty) _toController.text = to;
      if (departure.isNotEmpty && _departureOptions.contains(departure)) {
        _selectedDeparture = departure;
      }
      if (from.isNotEmpty && to.isNotEmpty) _pendingAutoSearch = true;

      _tryAutoFillLocation();
      context.read<RideViewModel>().loadAvailableRides();
      _locationServiceStream = Geolocator.getServiceStatusStream().listen(
        (ServiceStatus status) {
          if (status == ServiceStatus.enabled && mounted) {
            setState(() => _locationServiceDisabled = false);
            _tryAutoFillLocation();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _locationServiceStream?.cancel();
    _fromController.removeListener(_onFromChanged);
    _toController.removeListener(_onToChanged);
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onFromChanged() {
    if (_ignoreNextFromChange) {
      _ignoreNextFromChange = false;
      return;
    }
    if (_gpsAutoFilled) {
      setState(() => _gpsAutoFilled = false);
    }
    _resetSearchIfBothEmpty();
  }

  void _onToChanged() {
    _resetSearchIfBothEmpty();
  }

  void _resetSearchIfBothEmpty() {
    if (_fromController.text.isEmpty && _toController.text.isEmpty && _hasSearched) {
      setState(() {
        _hasSearched = false;
        _filteredRides = [];
        _activeFilter = 'All';
      });
    }
  }

  // Feature 2 — GPS auto-fill FROM field (zone detection via shared utility)
  Future<void> _tryAutoFillLocation() async {
    if (_fromController.text.isNotEmpty) return; // already filled, skip GPS

    // Check service separately to control the disabled banner
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationServiceDisabled = true);
      return;
    }
    if (mounted) setState(() => _locationServiceDisabled = false);

    final zone = await LocationUtils.detectZone();
    if (zone != null && mounted) {
      _ignoreNextFromChange = true;
      _fromController.text = zone;
      setState(() => _gpsAutoFilled = true);
    }
  }

  // Level 1 — Primary filter (Search button)
  void _onSearch() {
    final allRides = context.read<RideViewModel>().rides;
    final from = _fromController.text.trim().toLowerCase();
    final to = _toController.text.trim().toLowerCase();
    final now = DateTime.now();

    DateTime windowStart;
    DateTime windowEnd;
    switch (_selectedDeparture) {
      case 'In 30 min':
        windowStart = now.add(const Duration(minutes: 15));
        windowEnd = now.add(const Duration(minutes: 60));
      case 'In 1 hour':
        windowStart = now.add(const Duration(minutes: 45));
        windowEnd = now.add(const Duration(minutes: 90));
      case 'In 2 hours':
        windowStart = now.add(const Duration(minutes: 90));
        windowEnd = now.add(const Duration(minutes: 150));
      default: // 'Now'
        windowStart = now;
        windowEnd = now.add(const Duration(minutes: 30));
    }

    final results = allRides.where((r) {
      if (from.isNotEmpty && !r.origin.toLowerCase().contains(from)) return false;
      if (to.isNotEmpty && !r.destination.toLowerCase().contains(to)) return false;
      if (r.departureTime.isBefore(windowStart) || r.departureTime.isAfter(windowEnd)) {
        return false;
      }
      return true;
    }).toList();

    setState(() {
      _filteredRides = results;
      _hasSearched = true;
      _activeFilter = 'All';
    });
  }

  // Level 2 — Secondary filter (chips), applied on top of _filteredRides
  List<RideModel> _applyChipFilter(List<RideModel> rides) {
    switch (_activeFilter) {
      case 'High Reliability':
        return rides.where((r) => r.driverRating >= 4.5 && r.punctualityRate >= 0.90).toList();
      case 'Female Driver':
        return rides.where((r) => r.gender == 'female').toList();
      case '4.5+ Rating':
        return rides.where((r) => r.driverRating >= 4.5).toList();
      default: // 'All'
        return rides;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RideViewModel>();

    // Auto-search once rides finish loading (when navigated from Home)
    if (_pendingAutoSearch && !vm.isLoading && vm.rides.isNotEmpty) {
      _pendingAutoSearch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onSearch();
      });
    }

    final now = DateTime.now();
    final upcomingRides = vm.rides.where((r) => r.departureTime.isAfter(now)).toList();
    final sourceList = _hasSearched ? _filteredRides : upcomingRides;
    List<RideModel> displayed = _applyChipFilter(sourceList);
    if (_hasSearched) {
      displayed = List<RideModel>.from(displayed)
        ..sort((a, b) => _rankScore(b).compareTo(_rankScore(a)));
    }

    final sectionHeader = _hasSearched ? 'RECOMMENDED RIDES' : 'AVAILABLE RIDES';

    return Scaffold(
      backgroundColor: _RidesColors.background,
      appBar: AppBar(
        backgroundColor: _RidesColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _RidesColors.textPrimary),
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
              if (_locationServiceDisabled) const LocationDisabledBanner(),
              _buildSearchSummaryCard(),
              _FilterChipsRow(
                activeFilter: _activeFilter,
                onFilterChanged: (val) => setState(() => _activeFilter = val),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  sectionHeader,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _RidesColors.muted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    vm.errorMessage!,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.red),
                  ),
                )
              else if (displayed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Text(
                    _hasSearched
                        ? 'No rides found for your search. Try different origin or time.'
                        : 'No rides available right now.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _RidesColors.muted,
                      height: 1.5,
                    ),
                  ),
                )
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayed.length,
                  itemBuilder: (_, i) => _RideCard(
                    ride: displayed[i],
                    rank: i + 1,
                    isBestMatch: i == 0 && _hasSearched,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSummaryCard() {
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
          IntrinsicHeight(
            child: Row(
              children: [
                // FROM field (Feature 1 + Feature 2)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM',
                        style: GoogleFonts.poppins(fontSize: 10, color: _RidesColors.muted),
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
                          Expanded(
                            child: TextFormField(
                              controller: _fromController,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _RidesColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter origin zone',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _RidesColors.muted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                suffixIcon: _gpsAutoFilled
                                    ? const Icon(
                                        Icons.gps_fixed,
                                        size: 12,
                                        color: _RidesColors.primary,
                                      )
                                    : null,
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_gpsAutoFilled) ...[
                        const SizedBox(height: 3),
                        Text(
                          '📍 Detected automatically — tap to edit',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _RidesColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  color: _RidesColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                // TO field (Feature 1)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO',
                        style: GoogleFonts.poppins(fontSize: 10, color: _RidesColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: _RidesColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextFormField(
                              controller: _toController,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _RidesColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter destination',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _RidesColors.textPrimary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
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
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 14, color: _RidesColors.muted),
              const SizedBox(width: 4),
              Text(
                'Departure:',
                style: GoogleFonts.poppins(fontSize: 12, color: _RidesColors.muted),
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
                    items: _departureOptions
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDeparture = val!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 36,
                child: ElevatedButton(
                  onPressed: _onSearch,
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

  static const _filters = ['All', 'High Reliability', 'Female Driver', '4.5+ Rating'];

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
            color: isSelected ? _RidesColors.background : _RidesColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.ride,
    required this.rank,
    this.isBestMatch = false,
  });

  final RideModel ride;
  final int rank;
  final bool isBestMatch;

  @override
  Widget build(BuildContext context) {
    final String timeStr = _fmtTime(ride.departureTime);
    final String priceStr = _fmtPrice(ride.price);

    return GestureDetector(
      onTap: () => context.push('/rides/${ride.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _RidesColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _RidesColors.border),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0A000000)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Feature 5 — Rank row (#N + BEST MATCH badge)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _RidesColors.cardSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _RidesColors.border),
                  ),
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _RidesColors.muted,
                    ),
                  ),
                ),
                if (isBestMatch) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _RidesColors.bestMatchBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⭐ BEST MATCH',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _RidesColors.bestMatchText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // ROW 1 — driver info + reliability badge
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _RidesColors.primary,
                  child: Text(
                    ride.driverName.isNotEmpty ? ride.driverName[0] : '?',
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
                        ride.driverName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _RidesColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: _RidesColors.warningAmber),
                          const SizedBox(width: 2),
                          Text(
                            ride.driverRating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _RidesColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${(ride.punctualityRate * 100).toStringAsFixed(0)}% on-time',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                          Flexible(
                            child: Text(
                              ride.origin,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _RidesColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                          const Icon(Icons.location_on, size: 12, color: _RidesColors.muted),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              ride.destination,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _RidesColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _RidesColors.primary,
                      ),
                    ),
                    Text(
                      'ETA --',
                      style: GoogleFonts.poppins(fontSize: 12, color: _RidesColors.muted),
                    ),
                  ],
                ),
              ],
            ),

            // Feature 4 — Weather badge
            if (ride.hasRainForecast) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _RidesColors.rainBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🌧 Rain expected',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _RidesColors.rainText,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: _RidesColors.border, height: 1),
            const SizedBox(height: 12),

            // ROW 3 — price + seats + reserve
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _RidesColors.textPrimary,
                        ),
                      ),
                      if (ride.seatsAvailable == 1)
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
                          '${ride.seatsAvailable} seats left',
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
                          'Ride reserved with ${ride.driverName}!',
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
      ),
    );
  }
}

