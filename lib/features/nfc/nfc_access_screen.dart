import 'package:flutter/material.dart';

class NfcAccessScreen extends StatelessWidget {
  const NfcAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NFC access',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              border: Border.all(color: const Color(0xFFC7D7FE)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.nfc, color: Color(0xFF2F5BFF)),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Ready to scan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}