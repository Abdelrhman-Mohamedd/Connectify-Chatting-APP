import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.createdAt,
    super.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  factory MessageModel.fromSupabase(Map<String, dynamic> json) {
    return MessageModel.fromJson(json);
  }
}
