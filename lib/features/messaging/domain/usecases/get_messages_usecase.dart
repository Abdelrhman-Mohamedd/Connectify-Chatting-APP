import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';

class GetMessagesUseCase implements UseCase<List<Message>, String> {
  final MessagingRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(String conversationId) async {
    return await repository.getMessages(conversationId);
  }
}
