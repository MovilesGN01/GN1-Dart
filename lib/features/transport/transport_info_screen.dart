import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/transport_info_service.dart';

class TransportInfoScreen extends StatefulWidget {
  const TransportInfoScreen({super.key});

  @override
  State<TransportInfoScreen> createState() => _TransportInfoScreenState();
}

class _TransportInfoScreenState extends State<TransportInfoScreen> {
  TransportInfoResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TransportInfoService().getTransportInfo();
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111111)),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Campus Transport'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final data = _result!.data;
    final source = _result!.source;

    // Support both key names used in different data sources
    final schedules =
        (data['schedules'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        (data['routes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    final lastUpdated =
        (data['last_updated'] as String?) ??
        (data['lastUpdated'] as String?) ??
        '';
    final service = data['service'] as String? ?? '';
    final provider = data['provider'] as String? ?? '';
    final routeName = data['route_name'] as String? ?? '';
    final fareCop = data['fare_cop'];
    final fareNote = data['fare_note'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (source == TransportInfoSource.fallback)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Color(0xFF92400E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing cached routes — connect to refresh.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF92400E)),
                  ),
                ),
                GestureDetector(
                  onTap: _load,
                  child: const Icon(Icons.refresh,
                      size: 16, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),

        // Route header card
        if (service.isNotEmpty || routeName.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.isNotEmpty)
                  Text(
                    service,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                if (provider.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    provider,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF1D4ED8)),
                  ),
                ],
                if (routeName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.route, size: 14, color: Color(0xFF1F5DFF)),
                      const SizedBox(width: 4),
                      Text(
                        routeName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ],
                if (fareCop != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 14, color: Color(0xFF16A34A)),
                      Text(
                        '\$${fareCop.toString()} COP',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
                if (fareNote.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fareNote,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF555555)),
                  ),
                ],
                if (lastUpdated.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Last updated: $lastUpdated',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),

        if (schedules.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No routes available.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: const Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ...schedules.map((s) => _ScheduleCard(schedule: s)),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final Map<String, dynamic> schedule;

  @override
  Widget build(BuildContext context) {
    // Support both 'schedules' items and legacy 'routes' items
    final shift = schedule['shift'] as String? ?? '';
    final direction = schedule['direction'] as String? ?? '';
    final name = schedule['name'] as String? ?? '';           // legacy key
    final origin = schedule['origin'] as String? ?? '';
    final destination = schedule['destination'] as String? ?? '';
    final scheduleStr = schedule['schedule'] as String? ?? ''; // legacy key
    final stops =
        (schedule['stops'] as List<dynamic>?)?.cast<String>() ?? [];
    final departures =
        (schedule['departures'] as List<dynamic>?)?.cast<String>() ?? [];

    final title = shift.isNotEmpty ? shift : name;
    final subtitle = direction.isNotEmpty ? direction : scheduleStr;

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                const Icon(Icons.directions_bus,
                    size: 18, color: Color(0xFF1F5DFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: const Color(0xFF1F5DFF)),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Origin → Destination
            if (origin.isNotEmpty || destination.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF1F5DFF)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      origin,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF555555)),
                    ),
                  ),
                ],
              ),
              Container(
                  width: 1,
                  height: 12,
                  margin: const EdgeInsets.only(left: 3),
                  color: const Color(0xFFE5E7EB)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      destination,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF555555)),
                    ),
                  ),
                ],
              ),
            ],

            // Departures
            if (departures.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    departures.join('  ·  '),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            ],

            // Stops
            if (stops.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: stops
                    .map(
                      (stop) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          stop,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: const Color(0xFF334155)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
