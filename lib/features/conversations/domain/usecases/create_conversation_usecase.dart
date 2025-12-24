import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter_messaging_app/features/conversations/domain/repositories/conversation_repository.dart';

class CreateConversationUseCase implements UseCase<Conversation, String> {
  final ConversationRepository repository;

  CreateConversationUseCase(this.repository);

  @override
  Future<Either<Failure, Conversation>> call(String otherUserId) async {
    return await repository.createConversation(otherUserId);
  }
}
