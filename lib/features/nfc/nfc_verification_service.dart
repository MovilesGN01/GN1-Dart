import 'dart:convert';
import 'package:http/http.dart' as http;

class NfcVerificationService {
  static const String _endpoint =
      'https://verifynfc-u4aratg3tq-uc.a.run.app';

  Future<bool> verifyTag(String tagId) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tagId': tagId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo verificar el tag NFC.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return (decoded['authorized'] as bool?) ?? false;
    }

    throw Exception('Respuesta inválida de verifyNFC.');
  }
}