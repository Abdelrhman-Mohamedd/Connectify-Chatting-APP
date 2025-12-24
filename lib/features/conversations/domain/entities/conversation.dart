import 'package:equatable/equatable.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';

class Conversation extends Equatable {
  final String id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final bool lastMessageIsRead;
  final List<UserEntity> participants;
  final int unreadCount;

  const Conversation({
    required this.id,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.lastMessageIsRead = false,
    this.participants = const [],
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [id, lastMessage, lastMessageAt, lastMessageSenderId, lastMessageIsRead, participants, unreadCount];
}
