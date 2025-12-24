import 'package:equatable/equatable.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();
  
  @override
  List<Object> get props => [];
}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<Conversation> conversations;

  const ConversationLoaded(this.conversations);

  @override
  List<Object> get props => [conversations];
}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError(this.message);

  @override
  List<Object> get props => [message];
}
