import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/connectivity_service.dart';
import '../data/chatbot_service.dart';
import '../models/chat_message.dart';

class ChatbotController extends ChangeNotifier {
  ChatbotController(this._service) {
    _setupConnectivityListener();
  }

  final ChatbotService _service;
  StreamSubscription<bool>? _connectivitySub;

  final List<ChatMessage> _messages = [];
  // Ordered queue of pending message IDs to retry in order.
  final Queue<String> _pendingQueue = Queue();
  // Map id → ChatMessage for O(1) lookup during retry.
  final Map<String, ChatMessage> _pendingMap = {};

  bool _isSending = false;
  bool _isOffline = false;
  bool _isSyncing = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  void _setupConnectivityListener() {
    _connectivitySub =
        ConnectivityService().onStatusChanged.listen((online) {
      final wasOffline = _isOffline;
      _isOffline = !online;
      notifyListeners();

      if (online && wasOffline && _pendingQueue.isNotEmpty) {
        _retryPending();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void loadWelcomeMessage() {
    if (_messages.isNotEmpty) return;
    _messages.add(
      ChatMessage(
        text:
            "Hi! I'm UniRide assistant.\nTell me your plan and I'll suggest the best commute.",
        isUser: false,
        createdAt: DateTime.now(),
        status: ChatMessageStatus.sent,
      ),
    );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isSending) return;

    final userMsg = ChatMessage(
      text: clean,
      isUser: true,
      createdAt: DateTime.now(),
      status: ChatMessageStatus.sending,
    );

    _messages.add(userMsg);
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final online = await ConnectivityService.instance.isOnline;

    if (!online) {
      _isOffline = true;
      _enqueuePending(userMsg);
      _isSending = false;
      notifyListeners();
      return;
    }

    await _dispatchMessage(userMsg);
    _isSending = false;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _enqueuePending(ChatMessage msg) {
    _updateStatus(msg.id, ChatMessageStatus.pendingSync);
    _pendingQueue.add(msg.id);
    _pendingMap[msg.id] = msg;
    debugPrint('[Chatbot] queued offline message ${msg.id}');
  }

  Future<void> _dispatchMessage(ChatMessage userMsg) async {
    try {
      final reply = await _service.sendMessage(userMsg.text);
      _updateStatus(userMsg.id, ChatMessageStatus.sent);
      _messages.add(
        ChatMessage(
          text: reply,
          isUser: false,
          createdAt: DateTime.now(),
          status: ChatMessageStatus.sent,
        ),
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _updateStatus(userMsg.id, ChatMessageStatus.failed);
      _messages.add(
        ChatMessage(
          text: 'I could not respond right now.',
          isUser: false,
          createdAt: DateTime.now(),
          status: ChatMessageStatus.sent,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _retryPending() async {
    if (_pendingQueue.isEmpty || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    while (_pendingQueue.isNotEmpty) {
      final id = _pendingQueue.first;
      final msg = _pendingMap[id];
      if (msg == null) {
        _pendingQueue.removeFirst();
        continue;
      }

      _updateStatus(id, ChatMessageStatus.sending);
      notifyListeners();

      await _dispatchMessage(msg);

      _pendingQueue.removeFirst();
      _pendingMap.remove(id);
    }

    _isSyncing = false;
    notifyListeners();
  }

  void _updateStatus(String id, ChatMessageStatus status) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(status: status);
    }
  }
}
