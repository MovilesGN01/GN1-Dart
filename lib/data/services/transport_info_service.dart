import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum TransportInfoSource { file, network, fallback }

class TransportInfoResult {
  final Map<String, dynamic> data;
  final TransportInfoSource source;
  const TransportInfoResult(this.data, this.source);
}

class TransportInfoService {
  static const _fileName = 'transport_info.json';
  static const _maxAgeHours = 24;

  Future<TransportInfoResult> getTransportInfo() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');

    // Serve from disk if fresh enough
    if (file.existsSync()) {
      final age = DateTime.now().difference(file.lastModifiedSync());
      if (age.inHours < _maxAgeHours) {
        debugPrint('[TransportInfo] serving from local file (age: ${age.inMinutes}min)');
        final raw = await file.readAsString();
        return TransportInfoResult(
          jsonDecode(raw) as Map<String, dynamic>,
          TransportInfoSource.file,
        );
      }
    }

    // Fetch from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('transport_info')
          .get();

      Map<String, dynamic> data;
      if (!doc.exists || doc.data() == null) {
        debugPrint('[TransportInfo] Firestore doc missing, using demo data');
        data = _demoData();
      } else {
        final raw = doc.data()!['data'];
        if (raw is String) {
          data = (jsonDecode(raw) as Map<String, dynamic>?) ?? _demoData();
        } else if (raw is Map<String, dynamic>) {
          data = raw;
        } else {
          data = _demoData();
        }
      }

      await file.writeAsString(jsonEncode(data));
      debugPrint('[TransportInfo] fetched from Firestore, saved to disk');
      return TransportInfoResult(data, TransportInfoSource.network);
    } catch (e) {
      debugPrint('[TransportInfo] Firestore fetch failed: $e');
      // Return stale file if available, otherwise demo data
      if (file.existsSync()) {
        debugPrint('[TransportInfo] serving stale file as fallback');
        final raw = await file.readAsString();
        return TransportInfoResult(
          jsonDecode(raw) as Map<String, dynamic>,
          TransportInfoSource.fallback,
        );
      }
      // No file at all — return demo data so the screen always shows something
      debugPrint('[TransportInfo] no cached file, returning demo data');
      return TransportInfoResult(_demoData(), TransportInfoSource.fallback);
    }
  }

  static Map<String, dynamic> _demoData() => {
        'service': 'Pásate a la Ruta',
        'provider': 'Universidad de los Andes',
        'route_name': 'Ruta Carrera Séptima',
        'schedules': [
          {
            'shift': 'Jornada a.m.',
            'direction': 'Norte → Campus',
            'origin': 'Calle 147 con Carrera 19',
            'destination': 'Universidad de los Andes - Edificio ML',
            'stops': ['Calle 147', 'Carrera 7', 'Calle 26', 'Edificio ML'],
            'departures': ['5:00 a.m.', '6:00 a.m.'],
          },
        ],
        'last_updated': '2025-04',
      };
}
