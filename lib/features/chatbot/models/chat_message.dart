import 'package:uuid/uuid.dart';

enum ChatMessageStatus { sending, sent, failed, pendingSync }

class ChatMessage {
  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  ChatMessageStatus status;

  ChatMessage copyWith({ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      text: text,
      isUser: isUser,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
