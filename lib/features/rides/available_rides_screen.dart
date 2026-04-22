import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'ride_viewmodel.dart';

abstract final class _RidesColors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const cardSurface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const urgent = Color(0xFFFF3B30);
  static const success = Color(0xFF34C759);
  static const successLight = Color(0xFFE8F5E9);
  static const successText = Color(0xFF2E7D32);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFF3E8FF);
  static const purpleText = Color(0xFF6D28D9);
  static const warningAmber = Color(0xFFF59E0B);
}

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  String _selectedDeparture = 'Now';
  String _activeFilter = 'All';

  static const List<String> _departureOptions = <String>[
    'Now',
    '7:00 AM',
    '7:30 AM',
    '8:00 AM',
    '8:30 AM',
  ];

  static const List<String> _filters = <String>[
    'All',
    'High Reliability',
    'Female Driver',
    '4.5+ Rating',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<RideViewModel>().loadAvailableRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RidesColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop(); // 👈 vuelve a rides
            },
          ),
          title: Text(
            'Ride Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Consumer<RideViewModel>(
          builder: (context, vm, _) {
            final filteredRides = _applyFilters(vm.rides);

            return RefreshIndicator(
              onRefresh: vm.loadAvailableRides,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _SearchSummaryCard(
                    selectedDeparture: _selectedDeparture,
                    departureOptions: _departureOptions,
                    onDepartureChanged: (value) {
                      setState(() => _selectedDeparture = value);
                    },
                    onSearchPressed: () {
                      setState(() {});
                    },
                  ),
                  _FilterChipsRow(
                    filters: _filters,
                    activeFilter: _activeFilter,
                    onFilterChanged: (value) {
                      setState(() => _activeFilter = value);
                    },
                  ),
                  if (_activeFilter == 'Female Driver')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _RidesColors.purpleLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Este filtro queda pendiente hasta agregar '
                          '`isFemaleDriver` al modelo de lista.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _RidesColors.purpleText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'RECOMMENDED RIDES',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _RidesColors.muted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredRides.length} results',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _RidesColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (vm.isLoading && vm.rides.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (vm.errorMessage != null && vm.rides.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _ErrorCard(
                        message: vm.errorMessage!,
                        onRetry: vm.loadAvailableRides,
                      ),
                    )
                  else if (filteredRides.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: _EmptyStateCard(),
                    )
                  else
                    ...filteredRides.map(
                      (ride) => _RideCard(
                        ride: ride,
                        onTap: () => context.push('/rides/${ride.id}'),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<RideModel> _applyFilters(List<RideModel> rides) {
    final departureFiltered = rides.where(_matchesDeparture).toList();

    switch (_activeFilter) {
      case 'All':
        return departureFiltered;

      case 'High Reliability':
        return departureFiltered
            .where((ride) => ride.driverRating >= 4.8)
            .toList();

      case '4.5+ Rating':
        return departureFiltered
            .where((ride) => ride.driverRating >= 4.5)
            .toList();

      case 'Female Driver':
        return departureFiltered
            .where((ride) => ride.isFemaleDriver)
            .toList();

      default:
        return departureFiltered;
    }
  }
  
  bool _matchesDeparture(RideModel ride) {
    if (_selectedDeparture == 'Now') return true;

    final target = _parseTimeLabel(_selectedDeparture);
    if (target == null) return true;

    final rideMinutes = ride.departureTime.hour * 60 + ride.departureTime.minute;
    final targetMinutes = target.hour * 60 + target.minute;

    return rideMinutes >= targetMinutes;
  }

  TimeOfDay? _parseTimeLabel(String label) {
    if (label == 'Now') return null;

    final parts = label.split(' ');
    if (parts.length != 2) return null;

    final hm = parts[0].split(':');
    if (hm.length != 2) return null;

    final rawHour = int.tryParse(hm[0]);
    final minute = int.tryParse(hm[1]);
    if (rawHour == null || minute == null) return null;

    final suffix = parts[1].toUpperCase();
    int hour = rawHour;

    if (suffix == 'PM' && hour != 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _SearchSummaryCard extends StatelessWidget {
  const _SearchSummaryCard({
    required this.selectedDeparture,
    required this.departureOptions,
    required this.onDepartureChanged,
    required this.onSearchPressed,
  });

  final String selectedDeparture;
  final List<String> departureOptions;
  final ValueChanged<String> onDepartureChanged;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
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
                            'Any origin',
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
                            'Any destination',
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
                    value: selectedDeparture,
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
                    items: departureOptions
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onDepartureChanged(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 36,
                child: ElevatedButton(
                  onPressed: onSearchPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _RidesColors.primary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply',
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

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filters,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters
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
  const _RideCard({
    required this.ride,
    required this.onTap,
  });

  final RideModel ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          children: [
            // 👤 HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _RidesColors.primary,
                  child: Text(
                    _initialFromName(ride.driverName),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: _RidesColors.warningAmber,
                          ),
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
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 📍 ROUTE
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          Expanded(
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
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: _RidesColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
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
                  children: [
                    Text(
                      _formatTime(ride.departureTime),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _RidesColors.primary,
                      ),
                    ),
                    Text(
                      ride.zone.isEmpty ? ride.status : ride.zone,
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
            const Divider(height: 1),

            const SizedBox(height: 12),

            // 💰 FOOTER
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPrice(ride.price),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _RidesColors.textPrimary,
                        ),
                      ),
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
                  width: 112,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _RidesColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'See details',
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

  static String _initialFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  static String _formatTime(DateTime value) {
    final hour24 = value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12:$minute $period';
  }

  static String _formatPrice(double value) {
    final whole = value.round();
    final text = whole.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '\$$buffer';
  }
}


class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _RidesColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _RidesColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _RidesColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RidesColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 40,
            color: _RidesColors.muted,
          ),
          const SizedBox(height: 10),
          Text(
            'No rides available with the current filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _RidesColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another departure time or remove one of the filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _RidesColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}