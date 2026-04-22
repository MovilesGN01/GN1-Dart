import 'package:cloud_functions/cloud_functions.dart';

class ChatbotService {
  ChatbotService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<String> ask(String message) async {
    final text = message.trim();
    if (text.isEmpty) {
      return 'Cuéntame tu origen, destino y hora aproximada.';
    }

    try {
      final callable = _functions.httpsCallable('chatbotReply');
      final result = await callable.call(<String, dynamic>{
        'message': text,
      });

      final data = result.data;
      if (data is Map && data['reply'] is String && (data['reply'] as String).trim().isNotEmpty) {
        return data['reply'] as String;
      }

      return _fallback(text);
    } on FirebaseFunctionsException {
      return _fallback(text);
    } catch (_) {
      return _fallback(text);
    }
  }

  String _fallback(String text) {
    final q = text.toLowerCase();

    if (q.contains('chapinero') && q.contains('campus')) {
      return 'Te recomiendo revisar rides desde Chapinero hacia Campus con salida entre 7:10 y 7:35 AM.';
    }

    if (q.contains('uniandes') || q.contains('campus')) {
      return 'Puedo ayudarte a elegir un ride hacia Campus si me dices desde qué zona sales.';
    }

    if (q.contains('lluvia') || q.contains('lloviendo')) {
      return 'Si está lloviendo, prioriza rides con menos paradas y mejor confiabilidad.';
    }

    if (q.contains('seguro') || q.contains('seguridad')) {
      return 'Busca conductores con mejor rating y confirma el punto de encuentro antes de salir.';
    }

    return 'Dime tu origen, destino y hora, y te sugiero la mejor opción.';
  }
}