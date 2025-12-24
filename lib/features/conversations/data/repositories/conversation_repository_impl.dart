import 'package:fpdart/fpdart.dart';
import 'package:flutter_messaging_app/core/errors/failures.dart';
import 'package:flutter_messaging_app/features/conversations/data/datasources/conversation_remote_data_source.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter_messaging_app/features/conversations/domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource remoteDataSource;

  ConversationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      final conversations = await remoteDataSource.getConversations();
      return Right(conversations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> createConversation(String otherUserId) async {
    try {
      final conversation = await remoteDataSource.createConversation(otherUserId);
      return Right(conversation);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversationById(String id) async {
    try {
      final conversation = await remoteDataSource.getConversationById(id);
      return Right(conversation);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Conversation>>> getConversationsStream() {
    return remoteDataSource.getConversationsStream().map((conversations) {
      return Right<Failure, List<Conversation>>(conversations);
    }).handleError((error) {
      return Left<Failure, List<Conversation>>(ServerFailure(error.toString()));
    });
  }
  @override
  Future<Either<Failure, void>> deleteConversation(String conversationId) async {
    try {
      await remoteDataSource.deleteConversation(conversationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
