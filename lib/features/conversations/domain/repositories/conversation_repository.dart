import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';

abstract class ConversationRepository {
  Future<Either<Failure, List<Conversation>>> getConversations();
  Future<Either<Failure, Conversation>> createConversation(String otherUserId);
  Future<Either<Failure, Conversation>> getConversationById(String conversationId);
  Stream<Either<Failure, List<Conversation>>> getConversationsStream();
  Future<Either<Failure, void>> deleteConversation(String conversationId); // NewString id);
}
