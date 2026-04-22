import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nfc_service.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

enum _NfcStatus {
  ready,
  scanning,
  authorized,
  rejected,
  error,
}

class NfcAccessScreen extends StatefulWidget {
  const NfcAccessScreen({super.key});

  @override
  State<NfcAccessScreen> createState() => _NfcAccessScreenState();
}

class _NfcAccessScreenState extends State<NfcAccessScreen> {
  final NfcService _service = NfcService();

  // Reemplaza estos IDs por tags reales o muévelos a backend / Firestore.
  final Set<String> _allowedTagIds = {
    '04AABBCCDD11',
    '1234567890AB',
  };

  _NfcStatus _status = _NfcStatus.ready;
  String _statusMessage = 'Acerca tu carné o tu celular para validar acceso.';
  NfcScanResult? _lastScan;

  Future<void> _startScan() async {
    setState(() {
      _status = _NfcStatus.scanning;
      _statusMessage = 'Escaneando... acerca el tag al dispositivo.';
    });

    try {
      final result = await _service.scan();
      final isAuthorized = _allowedTagIds.contains(result.id.toUpperCase());

      setState(() {
        _lastScan = result;
        _status = isAuthorized ? _NfcStatus.authorized : _NfcStatus.rejected;
        _statusMessage = isAuthorized
            ? 'Acceso validado. Puedes abordar o ingresar al punto de encuentro.'
            : 'Tag no autorizado para este acceso.';
      });
    } catch (e) {
      setState(() {
        _status = _NfcStatus.error;
        _statusMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _reset() {
    setState(() {
      _status = _NfcStatus.ready;
      _statusMessage = 'Acerca tu carné o tu celular para validar acceso.';
      _lastScan = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusData = _statusUi(_status);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'NFC access',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusData.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusData.accent.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusData.icon, color: statusData.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusData.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _status == _NfcStatus.scanning
                        ? Icons.nfc_rounded
                        : Icons.contactless_rounded,
                    size: 72,
                    color: statusData.accent,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _status == _NfcStatus.scanning
                        ? 'Scanning...'
                        : 'Ready to scan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa tu carné o celular con NFC',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _status == _NfcStatus.scanning ? null : _startScan,
                  icon: const Icon(Icons.nfc_rounded),
                  label: Text(
                    _status == _NfcStatus.scanning
                        ? 'Scanning...'
                        : 'Start scan',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    backgroundColor: const Color(0xFF1F5DFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF1F5DFF).withOpacity(0.45),
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
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    foregroundColor: const Color(0xFF1F5DFF),
                    side: const BorderSide(color: Color(0xFFD6E4FF)),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last scan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow('Tag ID', _lastScan?.id ?? '—'),
                const Divider(height: 24),
                _infoRow('Type', _lastScan?.type ?? '—'),
                const Divider(height: 24),
                _infoRow('Standard', _lastScan?.standard ?? '—'),
                const Divider(height: 24),
                _infoRow(
                  'Result',
                  _status == _NfcStatus.authorized
                      ? 'Authorized'
                      : _status == _NfcStatus.rejected
                          ? 'Rejected'
                          : 'Pending',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 3),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  _StatusUi _statusUi(_NfcStatus status) {
    switch (status) {
      case _NfcStatus.ready:
        return const _StatusUi(
          title: 'Ready to scan',
          icon: Icons.tap_and_play_outlined,
          accent: Color(0xFF1F5DFF),
          background: Color(0xFFEFF4FF),
        );
      case _NfcStatus.scanning:
        return const _StatusUi(
          title: 'Scanning',
          icon: Icons.nfc_rounded,
          accent: Color(0xFFF59E0B),
          background: Color(0xFFFFF7E6),
        );
      case _NfcStatus.authorized:
        return const _StatusUi(
          title: 'Authorized',
          icon: Icons.verified_rounded,
          accent: Color(0xFF34C759),
          background: Color(0xFFE8F5E9),
        );
      case _NfcStatus.rejected:
        return const _StatusUi(
          title: 'Rejected',
          icon: Icons.cancel_rounded,
          accent: Color(0xFFEF4444),
          background: Color(0xFFFEE2E2),
        );
      case _NfcStatus.error:
        return const _StatusUi(
          title: 'Error',
          icon: Icons.error_rounded,
          accent: Color(0xFFEF4444),
          background: Color(0xFFFEE2E2),
        );
    }
  }
}

class _StatusUi {
  final String title;
  final IconData icon;
  final Color accent;
  final Color background;

  const _StatusUi({
    required this.title,
    required this.icon,
    required this.accent,
    required this.background,
  });
}