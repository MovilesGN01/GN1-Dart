import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uniride/core/theme.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'UniRide',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 0),
      body: Center(
        child: Text(
          'Home – próximamente',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}