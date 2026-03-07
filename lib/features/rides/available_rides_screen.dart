import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AvailableRidesScreen extends StatelessWidget {
  const AvailableRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Viajes disponibles',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Text(
          'Próximamente',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}