import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';

class MarkMessagesAsReadUseCase implements UseCase<void, String> {
  final MessagingRepository repository;

  MarkMessagesAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String conversationId) async {
    return await repository.markMessagesAsRead(conversationId);
  }
}
