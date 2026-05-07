import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uniride/features/auth/auth_viewmodel.dart';
import 'package:uniride/shared/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
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
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F5DFF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'J',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning,',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Juan',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF1F5DFF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Uniandes · Verified Student',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1F5DFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF1F5DFF).withValues(alpha: 0.14),
              ),
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
                  child: const Icon(
                    Icons.contactless_rounded,
                    color: Color(0xFF1F5DFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFC access',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valida tu acceso con carné o celular NFC.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.push('/nfc'),
                  child: Text(
                    'Open',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F5DFF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Role management section
          Consumer<AuthViewModel>(
            builder: (context, auth, __) {
              final role = auth.currentUser?.role ?? 'passenger';
              final userId = auth.currentUser?.id ?? '';

              Future<void> upgradeRole() async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'role': 'both'});
                await auth.refreshCurrentUser();
              }

              Future<void> showUpgradeDialog(String description) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Switch to Both mode',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    content: Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF64748B))),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F5DFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Confirm',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await upgradeRole();
              }

              Widget _chip(
                String label,
                IconData icon, {
                required bool isActive,
                VoidCallback? onTap,
              }) {
                return GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1F5DFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF1F5DFF)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (role == 'both') ...[
                      Row(
                        children: [
                          _chip(
                            'Driver',
                            Icons.drive_eta,
                            isActive: auth.activeMode == 'driver',
                            onTap: () => auth.setActiveMode('driver'),
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            'Passenger',
                            Icons.person,
                            isActive: auth.activeMode == 'passenger',
                            onTap: () => auth.setActiveMode('passenger'),
                          ),
                        ],
                      ),
                    ] else if (role == 'driver') ...[
                      _chip('Driver', Icons.drive_eta, isActive: true),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => showUpgradeDialog(
                          'Switching to Both mode allows you to create rides as a driver while also booking rides as a passenger.',
                        ),
                        icon: const Icon(Icons.person_outlined,
                            size: 16, color: Color(0xFF1F5DFF)),
                        label: Text(
                          'Add passenger mode',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F5DFF),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ] else ...[
                      _chip('Passenger', Icons.person, isActive: true),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => showUpgradeDialog(
                          'Switching to Both mode allows you to create rides as a driver while also booking rides as a passenger.',
                        ),
                        icon: const Icon(Icons.drive_eta_outlined,
                            size: 16, color: Color(0xFF1F5DFF)),
                        label: Text(
                          'Add driver mode',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F5DFF),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          _SectionCard(
            title: 'Personal information',
            children: const [
              _InfoRow(label: 'Email', value: 'juan@uniandes.edu.co'),
              _InfoRow(label: 'Phone', value: '+57 300 000 0000'),
              _InfoRow(label: 'Campus', value: 'Universidad de los Andes'),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Preferences',
            children: const [
              _InfoRow(label: 'Preferred zone', value: 'Chapinero'),
              _InfoRow(label: 'Role', value: 'Passenger'),
              _InfoRow(label: 'Payment method', value: 'Card ending in 4242'),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Activity',
            children: const [
              _InfoRow(label: 'Completed rides', value: '12'),
              _InfoRow(label: 'Rating', value: '4.9'),
              _InfoRow(label: 'Saved routes', value: '3'),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
              label: Text(
                'Log out',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Log out',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    content: Text(
                      'Are you sure you want to log out?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(
                          'Log out',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if ((confirmed ?? false) && context.mounted) {
                  await context.read<AuthViewModel>().signOut();
                  if (context.mounted) context.go('/');
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const UniRideBottomNav(currentIndex: 4),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
      ),
    );
  }
}