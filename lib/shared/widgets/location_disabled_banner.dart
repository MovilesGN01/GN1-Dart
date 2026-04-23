import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationDisabledBanner extends StatelessWidget {
  const LocationDisabledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enable location to auto-detect your origin',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
          TextButton(
            onPressed: () async => Geolocator.openLocationSettings(),
            child: const Text('Enable', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
