import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter_messaging_app/features/conversations/domain/repositories/conversation_repository.dart';

class GetConversationByIdUseCase implements UseCase<Conversation, String> {
  final ConversationRepository repository;

  GetConversationByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Conversation>> call(String params) async {
    return await repository.getConversationById(params);
  }
}
