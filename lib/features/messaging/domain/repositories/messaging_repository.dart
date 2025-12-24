import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';

abstract class MessagingRepository {
  Stream<List<Message>> getMessagesStream(String conversationId);
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String content,
  });
  Future<Either<Failure, void>> markMessagesAsRead(String conversationId);
  Future<Either<Failure, void>> deleteMessage(String messageId);
}
