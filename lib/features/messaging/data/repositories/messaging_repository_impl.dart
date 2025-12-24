import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/messaging/data/datasources/messaging_remote_data_source.dart';
import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingRemoteDataSource remoteDataSource;

  MessagingRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return remoteDataSource.getMessagesStream(conversationId);
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String conversationId) async {
    try {
      final messages = await remoteDataSource.getMessages(conversationId);
      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({required String conversationId, required String content}) async {
    try {
      final message = await remoteDataSource.sendMessage(
        conversationId: conversationId,
        content: content,
      );
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(String conversationId) async {
    try {
      await remoteDataSource.markMessagesAsRead(conversationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
