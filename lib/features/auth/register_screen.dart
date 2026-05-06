import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/offline_banner.dart';
import 'register_viewmodel.dart';

Widget? _limitCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) {
  if (maxLength == null || currentLength < maxLength) return null;
  return Text(
    'Max $maxLength characters',
    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFFF3B30)),
  );
}

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RegisterViewModel>().checkConnectivity();
      }
    });
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
    return Consumer<RegisterViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: _Colors.background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                Consumer<RegisterViewModel>(
                  builder: (context, vm, child) => OfflineBanner(
                    isOffline: vm.isOffline,
                    isFromCache: false,
                    messageOverride: 'No connection - Connect to the network',
                  ),
                ),
                Expanded(
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
                        maxLength: 60,
                        buildCounter: _limitCounter,
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
                        maxLength: 100,
                        buildCounter: _limitCounter,
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
                        maxLength: 64,
                        buildCounter: _limitCounter,
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
                        maxLength: 64,
                        buildCounter: _limitCounter,
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

                      // Gender selector
                      Row(
                        children: [
                          Expanded(
                            child: _RoleButton(
                              label: 'Male',
                              icon: Icons.male,
                              selected: vm.gender == 'male',
                              onTap: () => vm.setGender('male'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RoleButton(
                              label: 'Female',
                              icon: Icons.female,
                              selected: vm.gender == 'female',
                              onTap: () => vm.setGender('female'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RoleButton(
                              label: 'Other',
                              icon: Icons.people_outline,
                              selected: vm.gender == 'other',
                              onTap: () => vm.setGender('other'),
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
                                      'ABC123',
                                      Icons.directions_car_outlined,
                                    ),
                                    maxLength: 7,
                                    buildCounter: _limitCounter,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-z0-9]')),
                                    ],
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
              ],
            ),
          ),
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
