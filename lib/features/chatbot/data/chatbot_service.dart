import 'package:cloud_functions/cloud_functions.dart';

class ChatbotService {
  ChatbotService()
      : _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<String> sendMessage(String message) async {
    final callable = _functions.httpsCallable('chatbot');

    final result = await callable.call(<String, dynamic>{
      'message': message,
    });

    final data = result.data;

    if (data is Map && data['reply'] is String) {
      return data['reply'] as String;
    }

    throw Exception('Formato de respuesta no reconocido.');
  }
}