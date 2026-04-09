import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcScanResult {
  final String id;
  final String type;
  final String standard;

  const NfcScanResult({
    required this.id,
    required this.type,
    required this.standard,
  });
}

class NfcService {
  Future<NfcScanResult> scan() async {
    final availability = await FlutterNfcKit.nfcAvailability;

    if (availability != NFCAvailability.available) {
      throw Exception('NFC no disponible en este dispositivo.');
    }

    final tag = await FlutterNfcKit.poll(
      timeout: const Duration(seconds: 12),
    );

    try {
      return NfcScanResult(
        id: tag.id,
        type: tag.type.name,
        standard: tag.standard ?? 'unknown',
      );
    } finally {
      await FlutterNfcKit.finish();
    }
  }
}