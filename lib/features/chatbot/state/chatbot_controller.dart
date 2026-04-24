import 'package:flutter/foundation.dart';

import '../data/chatbot_service.dart';
import '../models/chat_message.dart';

class ChatbotController extends ChangeNotifier {
  ChatbotController(this._service);

  final ChatbotService _service;

  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  void loadWelcomeMessage() {
    if (_messages.isNotEmpty) return;

    _messages.add(
      ChatMessage(
        text:
            "Hi! I’m UniRide assistant.\nTell me your plan and I’ll suggest the best commute.",
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isSending) return;

    _messages.add(
      ChatMessage(
        text: clean,
        isUser: true,
        createdAt: DateTime.now(),
      ),
    );

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _service.sendMessage(clean);

      _messages.add(
        ChatMessage(
          text: reply,
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _messages.add(
        ChatMessage(
          text: 'I could not respond right now.',
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}