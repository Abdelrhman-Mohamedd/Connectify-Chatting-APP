import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/core/config/routes/app_router.dart';
import 'package:flutter_messaging_app/core/di/service_locator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/core/config/theme/app_theme.dart';
import 'package:flutter_messaging_app/core/config/theme/theme_cubit.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// Conditional import for Windows-specific functionality
import 'package:flutter_messaging_app/core/platform/platform_init.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Platform-specific initialization
  // On Windows: ensures single instance
  // On Web/Other platforms: handles deep links through URL routing
  await initializePlatformSpecific(args);

  await setupServiceLocator();

  runApp(MyApp(initialArgs: args));
}

class MyApp extends StatelessWidget {
  final List<String> initialArgs;
  const MyApp({super.key, this.initialArgs = const []});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ThemeCubit>()), // Added ThemeCubit
        BlocProvider(
          create: (context) {
            final bloc = getIt<AuthBloc>()..add(AuthCheckRequested());
            if (initialArgs.isNotEmpty) {
              bloc.add(AuthDeepLinkReceived(initialArgs.first));
            }
            return bloc;
          },
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Connectify',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode, // Dynamic ThemeMode
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}


