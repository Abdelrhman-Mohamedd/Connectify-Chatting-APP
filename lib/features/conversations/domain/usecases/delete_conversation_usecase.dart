import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/conversations/domain/repositories/conversation_repository.dart';

class DeleteConversationUseCase {
  final ConversationRepository repository;

  DeleteConversationUseCase(this.repository);

  Future<Either<Failure, void>> call(String conversationId) {
    return repository.deleteConversation(conversationId);
  }
}
