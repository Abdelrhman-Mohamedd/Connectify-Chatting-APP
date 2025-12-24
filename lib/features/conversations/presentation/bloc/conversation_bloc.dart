import 'package:fpdart/fpdart.dart'; // Added
import 'package:flutter_messaging_app/core/errors/failures.dart'; // Added
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart'; // Added
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/get_conversations_usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/get_conversations_stream_usecase.dart'; 
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetConversationsUseCase getConversationsUseCase; // Restored
  final GetConversationsStreamUseCase getConversationsStreamUseCase;

  ConversationBloc({
    required this.getConversationsUseCase,
    required this.getConversationsStreamUseCase,
  }) : super(ConversationInitial()) {
    on<ConversationsRequested>(_onConversationsRequested);
  }

  Future<void> _onConversationsRequested(
      ConversationsRequested event, Emitter<ConversationState> emit) async {
    emit(ConversationLoading());
    
    // Subscribe to the stream
    final result = await getConversationsStreamUseCase(const NoParams());
    
    await result.fold(
      (failure) async => emit(ConversationError(failure.message)),
      (stream) async {
        await emit.forEach<Either<Failure, List<Conversation>>>(
          stream,
          onData: (result) => result.fold(
            (failure) => ConversationError(failure.message),
            (conversations) => ConversationLoaded(conversations),
          ),
          onError: (error, stackTrace) => ConversationError(error.toString()),
        );
      },
    );
  }
}
