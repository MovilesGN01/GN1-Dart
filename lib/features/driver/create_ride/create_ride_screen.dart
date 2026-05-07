import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/geocoding_service.dart';
import '../../../features/auth/auth_viewmodel.dart';
import '../../../shared/widgets/offline_banner.dart';
import 'create_ride_viewmodel.dart';

abstract final class _C {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const muted = Color(0xFF94A3B8);
  static const cardSurface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const danger = Color(0xFFFF3B30);
}

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, IconData icon,
      {Widget? suffix, String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: _C.muted),
      prefixIcon: Icon(icon, color: _C.muted),
      suffixIcon: suffix,
      suffixText: suffixText,
      suffixStyle: GoogleFonts.poppins(color: _C.muted, fontSize: 13),
      filled: true,
      fillColor: _C.cardSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.primary, width: 2),
      ),
    );
  }

  Future<void> _pickDepartureTime(CreateRideViewModel vm) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    vm.setDepartureTime(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Widget _suggestionList({
    required List<PlaceSuggestion> suggestions,
    required void Function(PlaceSuggestion) onSelect,
    required TextEditingController controller,
  }) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return ListTile(
            dense: true,
            leading:
                Icon(Icons.location_on, size: 18, color: Colors.grey[500]),
            title: Text(
              s.displayName,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            subtitle: Text(
              s.fullName.split(',').take(3).join(','),
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              onSelect(s);
              controller.text = s.displayName;
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateRideViewModel>();

    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        backgroundColor: _C.background,
        elevation: 0,
        title: Text(
          'Create Ride',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: _C.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            OfflineBanner(isOffline: vm.isOffline, isFromCache: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Origin search ───────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _originController,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: _C.textPrimary),
                          decoration: _fieldDecoration(
                            'Search origin...',
                            Icons.trip_origin,
                            suffix: vm.isSearchingOrigin
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (v) {
                            vm.originLat = null;
                            vm.searchOrigin(v);
                          },
                        ),
                        _suggestionList(
                          suggestions: vm.originSuggestions,
                          onSelect: vm.selectOrigin,
                          controller: _originController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Destination search ──────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _destinationController,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: _C.textPrimary),
                          decoration: _fieldDecoration(
                            'Search destination...',
                            Icons.location_on_outlined,
                            suffix: vm.isSearchingDestination
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (v) {
                            vm.destinationLat = null;
                            vm.searchDestination(v);
                          },
                        ),
                        _suggestionList(
                          suggestions: vm.destinationSuggestions,
                          onSelect: vm.selectDestination,
                          controller: _destinationController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Departure time ──────────────────────────────────
                    InkWell(
                      onTap: () => _pickDepartureTime(vm),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _fieldDecoration(
                            'Select departure time', Icons.access_time),
                        child: Text(
                          vm.departureTime != null
                              ? DateFormat('MMM d, yyyy – HH:mm')
                                  .format(vm.departureTime!)
                              : 'Select departure time',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: vm.departureTime != null
                                ? _C.textPrimary
                                : _C.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Seats stepper ───────────────────────────────────
                    Row(
                      children: [
                        Text(
                          'Seats available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _C.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: vm.seats == 1 ? _C.muted : _C.primary,
                          onPressed:
                              vm.seats == 1 ? null : vm.decrementSeats,
                        ),
                        Text(
                          '${vm.seats}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _C.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: vm.seats == 6 ? _C.muted : _C.primary,
                          onPressed:
                              vm.seats == 6 ? null : vm.incrementSeats,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Price ───────────────────────────────────────────
                    TextFormField(
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: _C.textPrimary),
                      decoration: _fieldDecoration(
                          '8000', Icons.attach_money,
                          suffixText: 'COP'),
                      onChanged: (v) => vm.price = double.tryParse(v) ?? 0,
                    ),

                    // ── Error ───────────────────────────────────────────
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _C.danger,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Publish button ──────────────────────────────────
                    ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () {
                              final user = context
                                  .read<AuthViewModel>()
                                  .currentUser!;
                              vm.createRide(
                                context,
                                user.id,
                                user.name,
                                user.driverRating,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: _C.background,
                        disabledBackgroundColor:
                            _C.primary.withValues(alpha: 0.45),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Publish ride'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
