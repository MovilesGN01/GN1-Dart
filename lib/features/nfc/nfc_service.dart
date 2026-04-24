import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NfcScanResult {
  final String id;
  final String type;
  final String standard;

  NfcScanResult({
    required this.id,
    required this.type,
    required this.standard,
  });
}

class NfcService {
  Future<bool> isAvailable() async {
    return NfcManager.instance.isAvailable();
  }

  Future<NfcScanResult> scan() async {
    final completer = Completer<NfcScanResult>();

    final available = await isAvailable();
    if (!available) {
      throw Exception('NFC no está disponible en este dispositivo.');
    }

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final data = tag.data;

          String id = '';
          String type = 'unknown';
          String standard = 'unknown';

          if (data.containsKey('nfca')) {
            final nfca = Map<String, dynamic>.from(data['nfca'] as Map);
            final identifier = (nfca['identifier'] as List?) ?? [];
            id = _bytesToHex(identifier);
            type = 'NFCA';
            standard = 'ISO 14443-3A';
          } else if (data.containsKey('mifareclassic')) {
            final mifare = Map<String, dynamic>.from(data['mifareclassic'] as Map);
            final identifier = (mifare['identifier'] as List?) ?? [];
            id = _bytesToHex(identifier);
            type = 'MIFARE Classic';
            standard = 'MIFARE';
          } else if (data.containsKey('mifareultralight')) {
            final mifare = Map<String, dynamic>.from(data['mifareultralight'] as Map);
            final identifier = (mifare['identifier'] as List?) ?? [];
            id = _bytesToHex(identifier);
            type = 'MIFARE Ultralight';
            standard = 'MIFARE';
          } else if (data.containsKey('ndef')) {
            type = 'NDEF';
            standard = 'NDEF';
            id = 'NDEF_TAG';
          }

          await NfcManager.instance.stopSession();

          if (!completer.isCompleted) {
            completer.complete(
              NfcScanResult(
                id: id.isEmpty ? 'UNKNOWN_TAG' : id,
                type: type,
                standard: standard,
              ),
            );
          }
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Error leyendo tag');
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('No se pudo leer el tag NFC.'),
            );
          }
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () async {
        await NfcManager.instance.stopSession(
          errorMessage: 'Tiempo de escaneo agotado',
        );
        throw Exception('Tiempo de escaneo agotado.');
      },
    );
  }

  String _bytesToHex(List<dynamic> bytes) {
    return bytes
        .map((b) => (b as int).toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}