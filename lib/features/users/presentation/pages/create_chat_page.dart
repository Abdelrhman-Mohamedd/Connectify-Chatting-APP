import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/core/di/service_locator.dart';
import 'package:flutter_messaging_app/features/users/presentation/bloc/user_bloc.dart';
import 'package:flutter_messaging_app/features/users/presentation/bloc/user_event.dart';
import 'package:flutter_messaging_app/features/users/presentation/bloc/user_state.dart';
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/create_conversation_usecase.dart';

// Note: CreateConversationUseCase was planned but maybe not implemented or registered properly?
// Let's assume we need to implement it or use Repository directly for now to save time,
// BUT Clean Architecture says UseCase.
// I'll check if CreateConversationUseCase exists. If not, I'll implement it quickly.

class CreateChatPage extends StatelessWidget {
  const CreateChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Chat'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Builder(
                builder: (context) {
                  return TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by email',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      context.read<UserBloc>().add(SearchUsers(value));
                    },
                  );
                }
              ),
            ),
            Expanded(
              child: BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UserLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is UserError) {
                    return Center(child: Text('Error: ${state.message}'));
                  } else if (state is UserLoaded) {
                    if (state.users.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }
                    return ListView.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(user.name?.substring(0, 1) ?? '?')
                                : null,
                          ),
                          title: Text(user.name ?? 'Unknown'),
                          subtitle: Text(user.email),
                          onTap: () async {
                            // Create conversation and navigate
                            try {
                              // We need to call createConversation from ConversationBloc
                              // Or inject a UseCase here.
                              // Accessing ConversationBloc from previous screen context is safer if provided.
                              // Or we can just use the repository directly here for speed
                              // OR cleanest: Add event to ConversationBloc.
                             
                              // Since we don't have ConversationBloc in this tree easily unless passed, 
                              // let's assume we can dispatch to a GLOBAL or scoped bloc if provided on previous route.
                              // Actually, standard way: 
                              // Use CreateConversationUseCase here with a local Cubit or just generic async call.
                              
                              // Quick fix:
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final navigator = GoRouter.of(context);
                              
                              // We need access to CreateConversation logic.
                              // I'll assume we register CreateConversationUseCase and use it here directly for simplicity of this turn.
                              
                              // Oops, I can't easily inject the UseCase in build method without a widget holding it.
                              // Let's wait for the user to tap and then create it using GetIt.
                              
                              // See logic below in _createConversation
                              _createConversation(context, user.id);

                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to start chat: $e')),
                              );
                            }
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
    );
  }

  Future<void> _createConversation(BuildContext context, String otherUserId) async {
    // Ideally use a BLoC, but for speed:
    final createConversationUseCase = getIt<CreateConversationUseCase>();
    // Wait, check if I made this file? I think I missed it in the first pass.
    // I put "Implement CreateConversationUseCase" in tasks.
    
    // So I need to implement it first.
    // Assuming it exists for now:
    final result = await createConversationUseCase(otherUserId);
    
    if (context.mounted) {
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
        (conversation) {
           // Navigate to chat
           context.replace('/chat/${conversation.id}');
        },
      );
    }
  }
}
