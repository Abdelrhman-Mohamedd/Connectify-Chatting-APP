import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object> get props => [id, conversationId, senderId, content, createdAt, isRead];
}
