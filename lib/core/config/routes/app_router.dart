import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter_messaging_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_messaging_app/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_messaging_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_messaging_app/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter_messaging_app/features/conversations/presentation/pages/conversations_page.dart';
import 'package:flutter_messaging_app/features/messaging/presentation/pages/chat_page.dart';
import 'package:flutter_messaging_app/features/users/presentation/pages/create_chat_page.dart';
import 'package:flutter_messaging_app/features/auth/presentation/pages/update_password_page.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_messaging_app/features/users/presentation/pages/people_page.dart';
import 'package:flutter_messaging_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_messaging_app/features/calls/presentation/pages/calls_page.dart';
import 'package:flutter_messaging_app/core/widgets/scaffold_with_navbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_messaging_app/core/di/service_locator.dart';
import 'dart:async';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final navigatorKey = GlobalKey<NavigatorState>(); // Public key for external access

final router = GoRouter(
  navigatorKey: navigatorKey,
  refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
  initialLocation: '/splash',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggingIn = state.uri.toString() == '/login';
    final isRegistering = state.uri.toString() == '/register';
    final isRecovering = state.uri.toString() == '/forgot-password'; // Allow forgot password page
    final isUpdatingPassword = state.uri.toString() == '/update-password';
    
    // If user clicks the recovery link, AuthBloc emits AuthPasswordRecovery
    if (authState is AuthPasswordRecovery && !isUpdatingPassword) {
      return '/update-password';
    }

    // If user is authenticated, redirect to home if they are on login/register/splash
    if (authState is AuthAuthenticated) {
       // Start: Modified Logic
       // If we are updating password, STAY THERE.
       if (isUpdatingPassword) {
         return null; 
       }
       // End: Modified Logic
       
       if (isLoggingIn || isRegistering || state.uri.toString() == '/splash') {
         return '/';
       }
    }

    // Global Guard: If unauthenticated, force login (unless on public route)
    if (authState is AuthUnauthenticated) {
      final isPublic = isLoggingIn || isRegistering || isRecovering || state.uri.toString() == '/splash' || state.uri.toString().startsWith('/verify-email');
      if (!isPublic) {
        return '/login';
      }
    }
    

    
    // Protection: If on update-password but NOT in recovery/authenticated mode, go to login
    // This handles cases where the link is invalid/expired and AuthBloc emits AuthError
    if (isUpdatingPassword && authState is! AuthPasswordRecovery && authState is! AuthAuthenticated) {
      return '/login';
    }

    return null;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ConversationsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calls',
              builder: (context, state) => const CallsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/people',
              builder: (context, state) => const PeoplePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/update-password',
      builder: (context, state) => const UpdatePasswordPage(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        final email = state.extra as String; 
        return VerifyEmailPage(email: email);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/chat/:id',
      parentNavigatorKey: navigatorKey, // Hides bottom nav
      builder: (context, state) {
        final conversationId = state.pathParameters['id']!;
        return ChatPage(conversationId: conversationId);
      },
    ),
    GoRoute(
      path: '/create-chat',
      parentNavigatorKey: navigatorKey, // Hides bottom nav
      builder: (context, state) => const CreateChatPage(),
    ),
  ],
);
