import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String _baseUrl =
      'https://chatbot-u4aratg3fq-uc.a.run.app';

  Future<String> sendMessage({
    required String message,
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'userId': userId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error del chatbot (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      if (decoded['reply'] is String) {
        return decoded['reply'] as String;
      }
      if (decoded['response'] is String) {
        return decoded['response'] as String;
      }
      if (decoded['message'] is String) {
        return decoded['message'] as String;
      }
    }

    if (decoded is String) {
      return decoded;
    }

    throw Exception('Formato de respuesta no reconocido.');
  }
}