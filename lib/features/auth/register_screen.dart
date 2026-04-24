import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user_repository.dart';
import 'register_viewmodel.dart';

abstract final class _Colors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const cardSurface = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5E7EB);
  static const danger = Color(0xFFFF3B30);
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(context.read<UserRepository>()),
      child: const _RegisterBody(),
    );
  }
}

class _RegisterBody extends StatefulWidget {
  const _RegisterBody();

  @override
  State<_RegisterBody> createState() => _RegisterBodyState();
}

class _RegisterBodyState extends State<_RegisterBody> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _plateController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;

  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final offline = results.contains(ConnectivityResult.none);
    if (mounted) {
      context.read<RegisterViewModel>().setOffline(offline);
      if (offline) _showOfflineSnackBar();
    }
  }

  void _showOfflineSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Registration requires an internet connection.',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: _Colors.muted),
      prefixIcon: Icon(icon, color: _Colors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: _Colors.cardSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _Colors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        final offline = results.isNotEmpty && results.first == ConnectivityResult.none;
        final vm = context.read<RegisterViewModel>();
        if (vm.isOffline != offline) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.setOffline(offline);
            if (offline) _showOfflineSnackBar();
          });
        }

        return Consumer<RegisterViewModel>(
          builder: (context, vm, _) {
            return Scaffold(
              backgroundColor: _Colors.background,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),

                      // Logo
                      Text(
                        'UniRide',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: _Colors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _Colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Full name
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: _Colors.textPrimary),
                        decoration: _fieldDecoration(
                            'Full name', Icons.person_outline),
                        onChanged: (v) => vm.name = v,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: _Colors.textPrimary),
                        decoration: _fieldDecoration(
                          'yourname@uniandes.edu.co',
                          Icons.email_outlined,
                        ),
                        onChanged: (v) => vm.email = v,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: _Colors.textPrimary),
                        decoration: _fieldDecoration(
                          'Password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _Colors.muted,
                            ),
                            onPressed: () =>
                                setState(() => _passwordVisible = !_passwordVisible),
                          ),
                        ),
                        onChanged: (v) => vm.password = v,
                      ),
                      const SizedBox(height: 16),

                      // Confirm password
                      TextFormField(
                        controller: _confirmController,
                        obscureText: !_confirmVisible,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: _Colors.textPrimary),
                        decoration: _fieldDecoration(
                          'Confirm password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _confirmVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _Colors.muted,
                            ),
                            onPressed: () =>
                                setState(() => _confirmVisible = !_confirmVisible),
                          ),
                        ),
                        onChanged: (v) => vm.confirmPassword = v,
                      ),
                      const SizedBox(height: 16),

                      // Role selector
                      Row(
                        children: [
                          Expanded(
                            child: _RoleButton(
                              label: 'Passenger',
                              icon: Icons.person_outline,
                              selected: vm.role == 'passenger',
                              onTap: () => vm.setRole('passenger'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleButton(
                              label: 'Driver',
                              icon: Icons.directions_car_outlined,
                              selected: vm.role == 'driver',
                              onTap: () => vm.setRole('driver'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Vehicle plate (animated)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) => SizeTransition(
                          sizeFactor: animation,
                          child: child,
                        ),
                        child: vm.showVehicleField
                            ? Column(
                                key: const ValueKey('plate'),
                                children: [
                                  TextFormField(
                                    controller: _plateController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: _Colors.textPrimary),
                                    decoration: _fieldDecoration(
                                      'ABC-123',
                                      Icons.directions_car_outlined,
                                    ),
                                    onChanged: (v) => vm.vehiclePlate = v,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              )
                            : const SizedBox(key: ValueKey('no-plate')),
                      ),

                      // Error message
                      if (vm.errorMessage != null) ...[
                        Text(
                          vm.errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _Colors.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 16),

                      // Create account button
                      ElevatedButton(
                        onPressed: (vm.isLoading || vm.isOffline)
                            ? null
                            : () => vm.register(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Colors.primary,
                          foregroundColor: _Colors.background,
                          disabledBackgroundColor:
                              _Colors.primary.withValues(alpha: 0.45),
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
                            : const Text('Create account'),
                      ),
                      const SizedBox(height: 16),

                      // Back to login
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          'Already have an account? Sign in',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _Colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _Colors.primary : _Colors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _Colors.primary : _Colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : _Colors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _Colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
