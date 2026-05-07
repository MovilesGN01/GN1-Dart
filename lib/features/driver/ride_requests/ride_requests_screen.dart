import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../data/models/ride_request_model.dart';
import '../../../shared/widgets/offline_banner.dart';
import 'accept_reject_sheet.dart';
import 'ride_requests_viewmodel.dart';

class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideRequestsViewModel>().loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RideRequestsViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vm.origin} → ${vm.destination}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Requests',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF555555),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
      ),
      body: Column(
        children: [
          OfflineBanner(
            isOffline: vm.isOffline,
            isFromCache: false,
          ),
          if (vm.isOffline)
            Container(
              width: double.infinity,
              color: Colors.amber[50],
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Actions unavailable offline',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.amber[800],
                ),
              ),
            ),
          Expanded(
            child: vm.isLoading && vm.requests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vm.requests.isEmpty
                    ? Center(
                        child: Text(
                          'No pending requests',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.requests.length,
                        itemBuilder: (context, index) {
                          return _RequestCard(
                            request: vm.requests[index],
                            vm: vm,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.vm});

  final RideRequestModel request;
  final RideRequestsViewModel vm;

  void _showSheet(BuildContext context, bool isAccepting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<RideRequestsViewModel>(
          builder: (ctx, viewModel, _) => AcceptRejectSheet(
            request: request,
            isAccepting: isAccepting,
            vm: viewModel,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        request.passengerName.isNotEmpty ? request.passengerName[0] : '?';
    final rating = request.passengerRating;

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1F5DFF),
          child: Text(
            initial.toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          request.passengerName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: List.generate(5, (i) {
            return Icon(
              i < rating.round() ? Icons.star : Icons.star_border,
              size: 14,
              color: Colors.amber,
            );
          }),
        ),
        trailing: vm.isOffline
            ? Text(
                'Offline',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _showSheet(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => _showSheet(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
