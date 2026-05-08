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

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'status': status.name,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      status: ChatMessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ChatMessageStatus.sent,
      ),
    );
  }
}
