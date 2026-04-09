import 'package:flutter/foundation.dart';
import '../data/chatbot_service.dart';
import '../models/chat_message.dart';

class ChatbotController extends ChangeNotifier {
  ChatbotController(this._service) {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text: "Hi! I'm UniRide assistant.\nTell me your plan and I'll suggest the best commute.",
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  final ChatbotService _service;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isSending = false;
  bool get isSending => _isSending;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;

    _messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        createdAt: DateTime.now(),
      ),
    );
    _isSending = true;
    notifyListeners();

    try {
      final reply = await _service.ask(text);
      _messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: reply,
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