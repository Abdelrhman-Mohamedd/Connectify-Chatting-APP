import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';

class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  final MessagingRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      conversationId: params.conversationId,
      content: params.content,
    );
  }
}

class SendMessageParams {
  final String conversationId;
  final String content;

  const SendMessageParams({required this.conversationId, required this.content});
}
