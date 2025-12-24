import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';

class DeleteMessageUseCase {
  final MessagingRepository repository;

  DeleteMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(String messageId) {
    return repository.deleteMessage(messageId);
  }
}
