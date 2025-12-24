import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object> get props => [];
}

class ConversationsRequested extends ConversationEvent {}

class ConversationCreated extends ConversationEvent {
  final String otherUserId;

  const ConversationCreated(this.otherUserId);

  @override
  List<Object> get props => [otherUserId];
}
