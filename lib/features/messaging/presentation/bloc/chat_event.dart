import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatStarted extends ChatEvent {
  final String conversationId;

  const ChatStarted(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class MessageSent extends ChatEvent {
  final String conversationId;
  final String content;

  const MessageSent({required this.conversationId, required this.content});

  @override
  List<Object> get props => [conversationId, content];
}

class MessageDeleted extends ChatEvent {
  final String messageId;

  const MessageDeleted(this.messageId);

  @override
  List<Object> get props => [messageId];
}

class DeleteConversation extends ChatEvent {
  final String conversationId;

  const DeleteConversation(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}
