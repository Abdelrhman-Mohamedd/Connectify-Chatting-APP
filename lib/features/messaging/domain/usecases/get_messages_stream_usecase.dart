import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';

class GetMessagesStreamUseCase {
  final MessagingRepository repository;

  GetMessagesStreamUseCase(this.repository);

  Stream<List<Message>> call(String conversationId) {
    return repository.getMessagesStream(conversationId);
  }
}
