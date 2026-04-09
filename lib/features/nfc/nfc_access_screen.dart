import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

import '../auth/auth_viewmodel.dart';

class NfcAccessScreen extends StatefulWidget {
  const NfcAccessScreen({super.key});

  @override
  State<NfcAccessScreen> createState() => _NfcAccessScreenState();
}

class _NfcAccessScreenState extends State<NfcAccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _timer;
  _NfcStatus _status = _NfcStatus.ready;
  String _statusMessage = 'Acerca tu carné o tu celular para validar acceso.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startDemoScan() {
    _timer?.cancel();
    setState(() {
      _status = _NfcStatus.scanning;
      _statusMessage = 'Escaneando credencial...';
    });

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _status = _NfcStatus.authorized;
        _statusMessage = 'Acceso validado. Puedes abordar o ingresar al punto de encuentro.';
      });
    });
  }

  void _resetDemo() {
    _timer?.cancel();
    setState(() {
      _status = _NfcStatus.ready;
      _statusMessage = 'Acerca tu carné o tu celular para validar acceso.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool authorized = _status == _NfcStatus.authorized;

    return Scaffold(
      backgroundColor: _NfcColors.background,
      appBar: AppBar(
        backgroundColor: _NfcColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'NFC access',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _NfcColors.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(
                status: _status,
                message: _statusMessage,
              ),
              const SizedBox(height: 18),
              _NfcScanner(animation: _pulseController, status: _status),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _status == _NfcStatus.scanning ? null : _startDemoScan,
                      icon: const Icon(Icons.nfc_rounded),
                      label: Text(_status == _NfcStatus.scanning ? 'Scanning...' : 'Start scan'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        backgroundColor: _NfcColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _NfcColors.primary.withOpacity(0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetDemo,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        foregroundColor: _NfcColors.primary,
                        side: const BorderSide(color: _NfcColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AccessPassCard(
                authorized: authorized,
                userName: context.watch<AuthViewModel>().currentUser?.name ?? 'Usuario',
                userEmail: context.watch<AuthViewModel>().currentUser?.email ?? '',
              ),
              const SizedBox(height: 16),
              const _TipsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NfcStatus { ready, scanning, authorized }

abstract final class _NfcColors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE5E7EB);
  static const cardSurface = Color(0xFFF8FAFC);
  static const success = Color(0xFF34C759);
  static const successLight = Color(0xFFE8F5E9);
  static const amber = Color(0xFFF59E0B);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.message,
  });

  final _NfcStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color background;
    final IconData icon;
    final String title;

    switch (status) {
      case _NfcStatus.ready:
        accent = _NfcColors.primary;
        background = _NfcColors.primary.withOpacity(0.08);
        icon = Icons.tap_and_play_outlined;
        title = 'Ready to scan';
      case _NfcStatus.scanning:
        accent = _NfcColors.amber;
        background = _NfcColors.amber.withOpacity(0.10);
        icon = Icons.nfc_rounded;
        title = 'Scanning';
      case _NfcStatus.authorized:
        accent = _NfcColors.success;
        background = _NfcColors.successLight;
        icon = Icons.verified_rounded;
        title = 'Authorized';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _NfcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _NfcColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NfcScanner extends StatelessWidget {
  const _NfcScanner({
    required this.animation,
    required this.status,
  });

  final Animation<double> animation;
  final _NfcStatus status;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (status) {
      _NfcStatus.authorized => _NfcColors.success,
      _NfcStatus.scanning => _NfcColors.amber,
      _ => _NfcColors.primary,
    };

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: _NfcColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _NfcColors.border),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final double pulse = 1 + (math.sin(animation.value * math.pi * 2) * 0.08);
          final double ringOpacity = status == _NfcStatus.scanning ? 0.25 : 0.12;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulse * 1.65,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(ringOpacity),
                  ),
                ),
              ),
              Transform.scale(
                scale: pulse * 1.25,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(ringOpacity + 0.06),
                  ),
                ),
              ),
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: accent.withOpacity(0.18), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 10),
                      blurRadius: 24,
                      color: Color(0x11000000),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      status == _NfcStatus.authorized ? Icons.check_circle_rounded : Icons.nfc_rounded,
                      size: 54,
                      color: accent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      status == _NfcStatus.authorized ? 'Validated' : 'Tap to validate',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _NfcColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UniRide pass',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _NfcColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccessPassCard extends StatelessWidget {
  const _AccessPassCard({
    required this.authorized,
    required this.userName,
    required this.userEmail,
  });

  final bool authorized;
  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: authorized ? _NfcColors.successLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: authorized ? _NfcColors.success.withOpacity(0.28) : _NfcColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Campus pass',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _NfcColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: authorized ? Colors.white.withOpacity(0.7) : _NfcColors.cardSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  authorized ? 'ACTIVE' : 'PENDING',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: authorized ? _NfcColors.success : _NfcColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _passRow('Passenger', userName),
          const Divider(height: 24),
          _passRow('Institutional email', userEmail),
          const Divider(height: 24),
          _passRow('Access mode', 'Uniandes ID / Mobile NFC'),
          const Divider(height: 24),
          _passRow('Last validation', authorized ? 'Hoy · 7:18 AM' : 'Aún sin validar'),
        ],
      ),
    );
  }

  Widget _passRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _NfcColors.muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _NfcColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _NfcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prototype notes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _NfcColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _TipItem(text: 'La animación es simulada: todavía no conecta con hardware NFC.'),
          const SizedBox(height: 10),
          const _TipItem(text: 'La validación puede reutilizarse luego para acceso a bus, edificio o punto de encuentro.'),
          const SizedBox(height: 10),
          const _TipItem(text: 'La pestaña Profile ahora puede servir como entrada al flujo de credencial digital.'),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 8, color: _NfcColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _NfcColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
