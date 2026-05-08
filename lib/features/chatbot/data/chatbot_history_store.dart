import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';

/// File-based persistence for the chatbot conversation history.
///
/// Uses a single JSON file inside the app documents directory. Reads happen
/// once per session at controller boot; writes are debounced by the caller
/// and run off the UI thread.
class ChatbotHistoryStore {
  ChatbotHistoryStore({this.fileName = 'chatbot_history.json'});

  final String fileName;
  static const int _maxStoredMessages = 100;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, fileName));
  }

  Future<List<ChatMessage>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[ChatbotHistoryStore] load failed: $e');
      return const [];
    }
  }

  Future<void> save(List<ChatMessage> messages) async {
    try {
      final file = await _file();
      final tail = messages.length > _maxStoredMessages
          ? messages.sublist(messages.length - _maxStoredMessages)
          : messages;
      final encoded = jsonEncode(tail.map((m) => m.toJson()).toList());
      await file.writeAsString(encoded, flush: false);
    } catch (e) {
      debugPrint('[ChatbotHistoryStore] save failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[ChatbotHistoryStore] clear failed: $e');
    }
  }
}
