import 'package:equatable/equatable.dart';
import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final Conversation? conversation;
  final Set<String> onlineUsers;

  const ChatLoaded(this.messages, {this.conversation, this.onlineUsers = const {}});

  @override
  List<Object?> get props => [messages, conversation, onlineUsers];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatConversationDeleted extends ChatState {
  const ChatConversationDeleted();
}
