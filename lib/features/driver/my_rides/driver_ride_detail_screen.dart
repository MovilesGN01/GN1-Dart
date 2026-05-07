import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'driver_ride_detail_viewmodel.dart';

abstract final class _C {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE5E7EB);
  static const cardSurface = Color(0xFFF8FAFC);
  static const green = Color(0xFF16A34A);
  static const blue = Color(0xFF2563EB);
  static const orange = Color(0xFFF97316);
  static const grey = Color(0xFF9CA3AF);
  static const red = Color(0xFFDC2626);
}

String _fmtTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $p';
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _fmtPrice(double p) {
  final n = p.toInt();
  if (n >= 1000) {
    return '\$${n ~/ 1000}.${(n % 1000).toString().padLeft(3, '0')}';
  }
  return '\$$n';
}

class DriverRideDetailScreen extends StatelessWidget {
  const DriverRideDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DriverRideDetailViewModel>();

    return PopScope(
      canPop: !vm.isEditing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && vm.isEditing) vm.cancelEditing();
      },
      child: Scaffold(
        backgroundColor: _C.background,
        appBar: _buildAppBar(context, vm),
        body: SafeArea(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.isEditing
                  ? _EditForm(vm: vm)
                  : _DetailView(vm: vm),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, DriverRideDetailViewModel vm) {
    if (vm.isEditing) {
      return AppBar(
        backgroundColor: _C.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _C.textPrimary),
          onPressed: vm.cancelEditing,
        ),
        title: Text(
          'Edit Ride',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: _C.primary),
            onPressed: () async {
              final saved = await vm.saveChanges();
              if (saved && context.mounted) context.pop(true);
            },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: _C.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _C.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Ride Detail',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _C.textPrimary,
        ),
      ),
      actions: [
        if (vm.canEdit) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _C.primary),
            onPressed: vm.startEditing,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: _C.red),
            onPressed: () => _showDeleteDialog(context, vm),
          ),
        ],
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, DriverRideDetailViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Delete Ride',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this ride? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, color: _C.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: _C.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final deleted = await vm.deleteRide();
              if (deleted && context.mounted) context.pop(true);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: _C.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail view ───────────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  const _DetailView({required this.vm});

  final DriverRideDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final ride = vm.ride;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RouteStop(label: ride.origin, isOrigin: true),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: _C.border,
                  ),
                ),
                _RouteStop(label: ride.destination, isOrigin: false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Trip details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 2),
                  blurRadius: 8,
                  color: Color(0x0A000000),
                ),
              ],
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: _fmtDate(ride.departureTime),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Departure',
                  value: _fmtTime(ride.departureTime),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.event_seat_outlined,
                  label: 'Seats available',
                  value: ride.seatsAvailable.toString(),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.attach_money_outlined,
                  label: 'Price',
                  value: '${_fmtPrice(ride.price)} COP',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 2),
                  blurRadius: 8,
                  color: Color(0x0A000000),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _StatusChip(status: ride.status),
                if (!vm.canEdit) ...[
                  const SizedBox(height: 12),
                  Text(
                    ride.status == 'in_progress'
                        ? 'This ride is currently in progress and cannot be modified.'
                        : 'This ride has been completed and cannot be modified.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _C.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              vm.errorMessage!,
              style: GoogleFonts.poppins(fontSize: 13, color: _C.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({required this.label, required this.isOrigin});

  final String label;
  final bool isOrigin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isOrigin ? _C.primary : _C.textPrimary,
            shape: BoxShape.circle,
          ),
          child: isOrigin
              ? null
              : const Icon(Icons.location_on, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.muted),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: _C.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: _C.border, height: 1);
  }
}

// ── Edit form ─────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  const _EditForm({required this.vm});

  final DriverRideDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Origin'),
          const SizedBox(height: 6),
          _StyledTextField(
            controller: vm.originCtrl,
            hint: 'Enter origin',
          ),
          const SizedBox(height: 16),

          _SectionLabel('Destination'),
          const SizedBox(height: 6),
          _StyledTextField(
            controller: vm.destCtrl,
            hint: 'Enter destination',
          ),
          const SizedBox(height: 16),

          _SectionLabel('Departure date & time'),
          const SizedBox(height: 6),
          _DateTimePicker(vm: vm),
          const SizedBox(height: 16),

          _SectionLabel('Seats available'),
          const SizedBox(height: 6),
          _SeatsStepper(vm: vm),
          const SizedBox(height: 16),

          _SectionLabel('Price (COP)'),
          const SizedBox(height: 6),
          _StyledTextField(
            controller: vm.priceCtrl,
            hint: 'e.g. 8000',
            keyboardType: TextInputType.number,
          ),

          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              vm.errorMessage!,
              style: GoogleFonts.poppins(fontSize: 13, color: _C.red),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final saved = await vm.saveChanges();
                if (saved && context.mounted) context.pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: vm.cancelEditing,
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _C.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _C.textSecondary,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: _C.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: _C.muted),
        filled: true,
        fillColor: _C.cardSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _C.primary),
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.vm});

  final DriverRideDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _C.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: _C.muted),
            const SizedBox(width: 10),
            Text(
              '${_fmtDate(vm.editTime)} · ${_fmtTime(vm.editTime)}',
              style: GoogleFonts.poppins(fontSize: 14, color: _C.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: vm.editTime.isAfter(now) ? vm.editTime : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(vm.editTime),
    );
    if (time == null) return;

    vm.setEditTime(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _SeatsStepper extends StatelessWidget {
  const _SeatsStepper({required this.vm});

  final DriverRideDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_seat_outlined, size: 18, color: _C.muted),
          const SizedBox(width: 10),
          Text(
            'Seats',
            style: GoogleFonts.poppins(fontSize: 14, color: _C.textPrimary),
          ),
          const Spacer(),
          _StepperButton(
            icon: Icons.remove,
            onTap: vm.decrementSeats,
            enabled: vm.editSeats > 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${vm.editSeats}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: vm.incrementSeats,
            enabled: vm.editSeats < 6,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? _C.primary : _C.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case 'available':
      case 'active':
        bg = const Color(0xFFDCFCE7);
        fg = _C.green;
        label = status == 'active' ? 'Active' : 'Available';
      case 'in_progress':
        bg = const Color(0xFFDBEAFE);
        fg = _C.blue;
        label = 'In Progress';
      case 'completed':
        bg = const Color(0xFFF3F4F6);
        fg = _C.grey;
        label = 'Completed';
      default:
        bg = const Color(0xFFFED7AA);
        fg = _C.orange;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
