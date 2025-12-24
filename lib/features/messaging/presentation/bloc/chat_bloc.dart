import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/features/messaging/domain/entities/message.dart';
import 'package:flutter_messaging_app/features/messaging/domain/usecases/get_messages_stream_usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/usecases/get_messages_usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/usecases/mark_messages_as_read_usecase.dart'; // New
import 'package:flutter_messaging_app/features/conversations/domain/usecases/delete_conversation_usecase.dart'; // New
import 'package:flutter_messaging_app/features/messaging/domain/usecases/delete_message_usecase.dart'; // New
import 'package:flutter_messaging_app/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/bloc/chat_event.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/bloc/chat_state.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/get_conversation_by_id_usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/entities/conversation.dart';
import 'package:flutter_messaging_app/core/services/presence_service.dart'; // New

// Internal events to handle stream updates
class _ChatMessagesUpdated extends ChatEvent {
  final List<Message> messages;
  final Conversation? conversation;
  final Set<String> onlineUsers; // New
  const _ChatMessagesUpdated(this.messages, {this.conversation, this.onlineUsers = const {}});
}

// New internal event for presence updates
class _OnlineUsersUpdated extends ChatEvent {
  final Set<String> onlineUsers;
  const _OnlineUsersUpdated(this.onlineUsers);
}

class _ChatErrorOccurred extends ChatEvent {
  final String error;
  const _ChatErrorOccurred(this.error);
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesStreamUseCase getMessagesStreamUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final MarkMessagesAsReadUseCase markMessagesAsReadUseCase;
  final DeleteMessageUseCase deleteMessageUseCase; // New
  final DeleteConversationUseCase deleteConversationUseCase; // New
  final GetConversationByIdUseCase getConversationByIdUseCase;
  final PresenceService presenceService; // New
  
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _presenceSubscription; // New

  ChatBloc({
    required this.getMessagesStreamUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.markMessagesAsReadUseCase,
    required this.deleteMessageUseCase, // New
    required this.deleteConversationUseCase, // New
    required this.getConversationByIdUseCase,
    required this.presenceService, // New
  }) : super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<MessageSent>(_onMessageSent);
    on<_ChatMessagesUpdated>(_onChatMessagesUpdated);
    on<_OnlineUsersUpdated>(_onOnlineUsersUpdated); // New
    on<DeleteConversation>(_onDeleteConversation); // New
    on<MessageDeleted>(_onMessageDeleted);
    on<_ChatErrorOccurred>(_onChatErrorOccurred);
  }

  Future<void> _onDeleteConversation(
      DeleteConversation event, Emitter<ChatState> emit) async {
      // No optimistic update usually needed as we navigate away.
      final result = await deleteConversationUseCase(event.conversationId);
      result.fold(
        (l) => add(_ChatErrorOccurred(l.message)),
        (r) {
           // Success - Presentation layer should listen to state, but we don't have a specific "Deleted" state.
           // We can emit a side effect or just assume the UI pops.
           // Better: emitted ChatConversationDeleted. But let's reuse ChatInitial or add a state.
           // For simplicity, we can emit ChatLoaded with empty conversation? No.
           // Let's create a ChatDeleted State or property.
           emit(const ChatConversationDeleted());
        }
      );
  }

  Future<void> _onMessageDeleted(
      MessageDeleted event, Emitter<ChatState> emit) async {
      
      final currentState = state;
      if (currentState is! ChatLoaded) return;
      
      // 1. Optimistic Update: Remove message from UI immediately
      final currentMessages = currentState.messages;
      final optimisticMessages = currentMessages.where((m) => m.id != event.messageId).toList();
      emit(ChatLoaded(
        optimisticMessages, 
        conversation: currentState.conversation,
        onlineUsers: currentState.onlineUsers,
      ));

      // 2. Perform Server Deletion
      final result = await deleteMessageUseCase(event.messageId);
      
      result.fold(
        (l) {
          // 3. Failure: Revert state (Add message back / Re-fetch)
          print('ChatBloc: Delete failed, reverting. Error: ${l.message}');
          // Re-emitting original state or refreshing
          emit(ChatLoaded(
            currentMessages, 
            conversation: currentState.conversation,
            onlineUsers: currentState.onlineUsers,
          ));
          add(_ChatErrorOccurred("Deletion failed: ${l.message}")); // Optional: Show error
        },
        (r) {
           // Success: Do nothing, Stream will eventually confirm (or keep optimistic state)
        }
      );
  }

  Future<void> _onChatStarted(
      ChatStarted event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    await _messagesSubscription?.cancel();
    await _presenceSubscription?.cancel(); // Cancel old subscription
    
    // 1. Fetch initial messages explicitly (Robustness fix)
    final messagesResult = await getMessagesUseCase(event.conversationId);
    
    // 2. Fetch Conversation Details
    final conversationResult = await getConversationByIdUseCase(event.conversationId);
    Conversation? conversation;
    
    conversationResult.fold(
      (l) => print('ChatBloc: Failed to load conversation details: ${l.message}'),
      (r) => conversation = r,
    );

    messagesResult.fold(
      (failure) => add(_ChatErrorOccurred(failure.message)),
      (messages) => add(_ChatMessagesUpdated(messages, conversation: conversation)),
    );

    // 3. Mark messages as read
    // Fire and forget, or handle error if needed
    markMessagesAsReadUseCase(event.conversationId);

    // 3. Subscribe to Presence
    _presenceSubscription = presenceService.onlineUsersStream.listen((onlineUsers) {
      add(_OnlineUsersUpdated(onlineUsers));
    });

    print('ChatBloc: Subscribing to messages for conversation: ${event.conversationId}');
    
    // 4. Subscribe to stream for realtime updates
    _messagesSubscription = getMessagesStreamUseCase(event.conversationId).listen(
      (messages) {
        print('ChatBloc: Received ${messages.length} messages from stream');
        add(_ChatMessagesUpdated(messages)); // Conversation will be preserved by handler logic
      },
      onError: (error) {
        print('ChatBloc: Stream error: $error');
        // Don't emit error here, just log, as we have initial data
      },
    );
  }

  Future<void> _onMessageSent(
      MessageSent event, Emitter<ChatState> emit) async {
    final result = await sendMessageUseCase(SendMessageParams(
      conversationId: event.conversationId,
      content: event.content,
    ));
    
    result.fold(
      (failure) {
        print('ChatBloc: MessageSend Failed: ${failure.message}');
        add(_ChatErrorOccurred(failure.message));
      },
      (message) {
         // Explicitly refresh messages to ensure UI update even if stream lags
         getMessagesUseCase(event.conversationId).then(
           (refreshResult) => refreshResult.fold(
             (l) => print('ChatBloc: Refresh Failed: ${l.message}'), 
             (messages) => add(_ChatMessagesUpdated(messages))
           )
         );
      },
    );
  }

  void _onChatMessagesUpdated(
      _ChatMessagesUpdated event, Emitter<ChatState> emit) {
      
    // Preserve existing conversation if new one is null
    Conversation? currentConversation = event.conversation;
    if (currentConversation == null && state is ChatLoaded) {
      currentConversation = (state as ChatLoaded).conversation;
    }
    
    // Preserve onlineUsers
    Set<String> currentOnlineUsers = const {};
    if (state is ChatLoaded) {
      currentOnlineUsers = (state as ChatLoaded).onlineUsers;
    }

    emit(ChatLoaded(event.messages, conversation: currentConversation, onlineUsers: currentOnlineUsers));
  }

  void _onOnlineUsersUpdated(
      _OnlineUsersUpdated event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(ChatLoaded(
        currentState.messages,
        conversation: currentState.conversation,
        onlineUsers: event.onlineUsers,
      ));
    }
  }

  void _onChatErrorOccurred(
      _ChatErrorOccurred event, Emitter<ChatState> emit) {
    emit(ChatError(event.error));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    return super.close();
  }
}
