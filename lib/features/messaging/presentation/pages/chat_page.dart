import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/core/di/service_locator.dart';
import 'package:flutter_messaging_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/bloc/chat_bloc.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/bloc/chat_event.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/bloc/chat_state.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    if (_messageController.text.trim().isEmpty) return;
    context.read<ChatBloc>().add(
          MessageSent(
            conversationId: widget.conversationId,
            content: _messageController.text,
          ),
        );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    UserEntity? currentUser;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }

    return BlocProvider(
      create: (context) => getIt<ChatBloc>()
        ..add(ChatStarted(widget.conversationId)),
      child: Builder(
        builder: (context) {
          return BlocListener<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state is ChatConversationDeleted) {
                // Navigate back to Conversation List
                 if (Navigator.canPop(context)) {
                   Navigator.pop(context);
                 }
              }
            },
            child: Scaffold(
            appBar: AppBar(
              title: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                   UserEntity? otherUser;
                   String otherUserName = 'Chat';
                   String? otherUserAvatar;
                   bool isOnline = false;

                   if (state is ChatLoaded && state.conversation != null) {
                     // Find other participant
                     final participants = state.conversation!.participants;
                     final otherParticipant = participants.where((p) => p.id != currentUser?.id).firstOrNull;
                     
                     if (otherParticipant != null) {
                       otherUser = otherParticipant;
                       otherUserName = otherUser.name ?? 'Unknown';
                       otherUserAvatar = otherUser.avatarUrl;
                       
                       // Check real-time presence
                       isOnline = state.onlineUsers.contains(otherUser.id);
                     }
                   }

                   return Row(
                    children: [
                       if (otherUserAvatar != null) ...[
                         CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(otherUserAvatar), 
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 10),
                       ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(otherUserName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          // Hide "Online" if not online
                          if (isOnline)
                            Text('Online', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              actions: [
                IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
                IconButton(icon: const Icon(Icons.call), onPressed: () {}),
                // Delete Conversation Button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                     showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete Chat'),
                        content: const Text('This will delete the entire conversation. Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<ChatBloc>().add(DeleteConversation(widget.conversationId));
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            body: Column(
              children: [
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                       if (state is ChatError) {
                        return Center(child: Text(state.message));
                      } else if (state is ChatLoaded) {
                        if (state.messages.isEmpty) {
                          return Center(child: Text('Say hello!', style: TextStyle(color: Colors.grey[400])));
                        }
                        return ListView.builder(
                          reverse: true, 
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            final isMe = message.senderId == currentUser?.id;
                            
                            
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress: () {
                                  if (!isMe) return; // Can't delete others' messages
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Delete Message'),
                                      content: const Text('Are you sure you want to delete this message?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.read<ChatBloc>().add(MessageDeleted(message.id));
                                            Navigator.of(dialogContext).pop();
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        message.content,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(height: 4),
                                        Icon(
                                          message.isRead ? Icons.done_all : Icons.check,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                       return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                           color: Theme.of(context).colorScheme.surfaceVariant,
                           shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {},
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                       Container(
                        decoration: BoxDecoration(
                           color: Theme.of(context).primaryColor,
                           shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          onPressed: () => _sendMessage(context),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}
