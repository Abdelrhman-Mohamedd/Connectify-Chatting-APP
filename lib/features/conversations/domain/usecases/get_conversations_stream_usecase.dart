import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter_messaging_app/features/conversations/domain/repositories/conversation_repository.dart';

class GetConversationsStreamUseCase implements UseCase<Stream<Either<Failure, List<Conversation>>>, NoParams> {
  final ConversationRepository repository;

  GetConversationsStreamUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<Either<Failure, List<Conversation>>>>> call(NoParams params) async {
    return Right(repository.getConversationsStream());
  }
}
