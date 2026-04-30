import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/offline_banner.dart';
import 'rate_ride_viewmodel.dart';

class RateRideSheet extends StatefulWidget {
  const RateRideSheet({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.userId,
  });

  final String rideId;
  final String driverId;
  final String driverName;
  final String userId;

  @override
  State<RateRideSheet> createState() => _RateRideSheetState();
}

class _RateRideSheetState extends State<RateRideSheet> {
  int _selectedStars = 0;

  static const _primary = Color(0xFF1F5DFF);
  static const _textPrimary = Color(0xFF111111);
  static const _textSecondary = Color(0xFF555555);
  static const _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RateRideViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RateRideViewModel>(
      builder: (context, vm, _) {
        if (vm.submitted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pop();
            final msg = vm.alreadyRated
                ? 'You have already rated this ride.'
                : vm.isOffline || _selectedStars == 0
                    ? 'Rating saved — will be submitted when you reconnect.'
                    : 'Rating submitted. Thank you!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  msg,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: _primary,
              ),
            );
          });
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                OfflineBanner(
                  isOffline: vm.isOffline,
                  isFromCache: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Rate this ride',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.driverName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final starIndex = i + 1;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedStars = starIndex),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                starIndex <= _selectedStars
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedStars == 0
                            ? 'Tap to rate'
                            : _labelForStars(_selectedStars),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _selectedStars == 0 || vm.isSubmitting
                              ? null
                              : () => _submit(context, vm),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            disabledBackgroundColor: _border,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: vm.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  vm.isOffline ? 'Save for later' : 'Submit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: _textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(
      BuildContext context, RateRideViewModel vm) async {
    await vm.submitRating(
      rideId: widget.rideId,
      driverId: widget.driverId,
      userId: widget.userId,
      stars: _selectedStars,
    );
  }

  static String _labelForStars(int stars) {
    switch (stars) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
