import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/ride_request_model.dart';
import 'ride_requests_viewmodel.dart';

class AcceptRejectSheet extends StatelessWidget {
  const AcceptRejectSheet({
    super.key,
    required this.request,
    required this.isAccepting,
    required this.vm,
  });

  final RideRequestModel request;
  final bool isAccepting;
  final RideRequestsViewModel vm;

  String _formatTime(DateTime dt) => DateFormat('MMM d, h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final titleText = isAccepting ? 'Accept Request' : 'Reject Request';
    final confirmColor = isAccepting ? const Color(0xFF1F5DFF) : Colors.red;
    final confirmText = isAccepting ? 'Confirm Accept' : 'Confirm Reject';
    final bodyText = isAccepting
        ? 'Accepting will reserve 1 seat for this passenger.'
        : 'This passenger will be notified that their request was not accepted.';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titleText,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        request.passengerName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        request.passengerRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested ${_formatTime(request.requestTime)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bodyText,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 24),
          if (vm.isOffline) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'No connection — cannot process now',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (vm.isOffline || vm.isLoading)
                      ? null
                      : () async {
                          if (isAccepting) {
                            await vm.acceptRequest(request.id, context);
                          } else {
                            await vm.rejectRequest(request.id, context);
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          confirmText,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
