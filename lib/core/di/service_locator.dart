import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_messaging_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_messaging_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_messaging_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/conversations/data/datasources/conversation_remote_data_source.dart';
import 'package:flutter_messaging_app/features/conversations/data/repositories/conversation_repository_impl.dart';
import 'package:flutter_messaging_app/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/create_conversation_usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/get_conversation_by_id_usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/get_conversations_usecase.dart';
import 'package:flutter_messaging_app/features/conversations/domain/usecases/get_conversations_stream_usecase.dart'; // New Import
import 'package:flutter_messaging_app/features/conversations/domain/usecases/delete_conversation_usecase.dart'; // New
import 'package:flutter_messaging_app/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:flutter_messaging_app/features/users/data/repositories/user_repository_impl.dart';
import 'package:flutter_messaging_app/features/users/domain/usecases/search_users_usecase.dart';
import 'package:flutter_messaging_app/features/users/presentation/bloc/user_bloc.dart';
import 'package:flutter_messaging_app/features/messaging/data/datasources/messaging_remote_data_source.dart';
import 'package:flutter_messaging_app/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:flutter_messaging_app/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_messaging_app/features/messaging/domain/usecases/get_messages_stream_usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/usecases/get_messages_usecase.dart'; 
import 'package:flutter_messaging_app/features/messaging/domain/usecases/mark_messages_as_read_usecase.dart'; // New
import 'package:flutter_messaging_app/features/messaging/domain/usecases/delete_message_usecase.dart'; // New
import 'package:flutter_messaging_app/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:flutter_messaging_app/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/bloc/chat_bloc.dart';
import 'package:flutter_messaging_app/core/config/theme/theme_cubit.dart';
import 'package:flutter_messaging_app/core/services/presence_service.dart'; // New

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External dependencies
  await dotenv.load(fileName: ".env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw Exception('Supabase URL or Key not found in .env');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton(() => PresenceService(getIt())); // New

  // 2. Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );

  // 3. Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );

  // 4. Use Cases
  getIt.registerLazySingleton(() => SignInUseCase(getIt()));
  getIt.registerLazySingleton(() => SignUpUseCase(getIt()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  getIt.registerLazySingleton(() => ResetPasswordUseCase(getIt()));
  getIt.registerLazySingleton(() => VerifyEmailUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));

  // 5. BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      signInUseCase: getIt(),
      signUpUseCase: getIt(),
      signOutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
      resetPasswordUseCase: getIt(),
      verifyEmailUseCase: getIt(),

      updateProfileUseCase: getIt(),
      presenceService: getIt(), // New
    ),
  );

  // Conversation Dependencies
  getIt.registerLazySingleton<ConversationRemoteDataSource>(
    () => ConversationRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetConversationsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetConversationsStreamUseCase(getIt())); // New UseCase
  getIt.registerLazySingleton(() => CreateConversationUseCase(getIt()));
  getIt.registerLazySingleton(() => GetConversationByIdUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteConversationUseCase(getIt())); // New

  getIt.registerFactory(() => ConversationBloc(
    getConversationsUseCase: getIt(),
    getConversationsStreamUseCase: getIt(), // New Injection
  ));

  // User Dependencies
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => SearchUsersUseCase(getIt()));
  getIt.registerFactory(() => UserBloc(searchUsersUseCase: getIt()));

  // Messaging Dependencies
  getIt.registerLazySingleton<MessagingRemoteDataSource>(
    () => MessagingRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetMessagesStreamUseCase(getIt()));
  getIt.registerLazySingleton(() => GetMessagesUseCase(getIt()));
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt()));
  getIt.registerLazySingleton(() => MarkMessagesAsReadUseCase(getIt())); // New
  getIt.registerLazySingleton(() => DeleteMessageUseCase(getIt())); // New

  getIt.registerFactory(
    () => ChatBloc(
      getMessagesStreamUseCase: getIt(),
      getMessagesUseCase: getIt(),
      sendMessageUseCase: getIt(),
      markMessagesAsReadUseCase: getIt(),
      deleteMessageUseCase: getIt(),
      
      deleteConversationUseCase: getIt(), // New

      getConversationByIdUseCase: getIt(),
      presenceService: getIt(), // New dependency
    ),
  );

  // Theme Cubit
  getIt.registerFactory(() => ThemeCubit());
}
