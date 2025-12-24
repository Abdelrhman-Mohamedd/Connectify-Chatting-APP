import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/core/di/service_locator.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart'; // New import
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ConversationBloc>()..add(ConversationsRequested()),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Connectify',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                     
                    IconButton(
                      icon: const Icon(Icons.edit_square, size: 28),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => context.push('/create-chat'),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Conversations List
              Expanded(
                child: BlocBuilder<ConversationBloc, ConversationState>(
                  builder: (context, state) {
                    if (state is ConversationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ConversationError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is ConversationLoaded) {
                      if (state.conversations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No conversations yet', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: state.conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = state.conversations[index];
                          final authState = context.read<AuthBloc>().state;
                          String? currentUserId;
                          if (authState is AuthAuthenticated) {
                            currentUserId = authState.user.id;
                          }

                          final others = conversation.participants.where((p) => p.id != currentUserId);
                          final otherParticipant = others.isNotEmpty ? others.first : conversation.participants.first;
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: otherParticipant.avatarUrl != null
                                  ? NetworkImage(otherParticipant.avatarUrl!)
                                  : null,
                              child: otherParticipant.avatarUrl == null
                                  ? Text(otherParticipant.name?.substring(0, 1) ?? '?', style: const TextStyle(fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            title: Text(
                              otherParticipant.name ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              conversation.lastMessage ?? 'No messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (conversation.lastMessageAt != null)
                                  Text(
                                    timeago.format(conversation.lastMessageAt!, locale: 'en_short'),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                const SizedBox(height: 5),
                                // Unread Count & Read Receipts
                                if (conversation.unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${conversation.unreadCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else if (currentUserId != null && conversation.lastMessageSenderId == currentUserId)
                                   Icon(
                                     conversation.lastMessageIsRead ? Icons.done_all : Icons.check, // Double check vs Single check
                                     size: 16,
                                     color: conversation.lastMessageIsRead ? Colors.blue : Colors.grey,
                                   ),
                              ],
                            ),
                            onTap: () {
                              context.push('/chat/${conversation.id}');
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
