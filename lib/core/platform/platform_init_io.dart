import 'dart:io' show Platform;
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:flutter_messaging_app/core/config/routes/app_router.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';

// IO platform initialization (Windows, Linux, macOS, Android, iOS)
Future<void> initializePlatformSpecific(List<String> args) async {
  // Only use WindowsSingleInstance on Windows platform
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "flutter_messaging_app_instance",
      onSecondWindow: (args) async {
        if (args.isNotEmpty) {
          final url = args.first;
          final context = navigatorKey.currentContext;
          if (context != null) {
            context.read<AuthBloc>().add(AuthDeepLinkReceived(url));
          }
        }
      },
    );
  }
// For other IO platforms (Linux, macOS, Android, iOS) (and Windows manual)
  
  // DEBUG: Listen to deep links explicitly to verify reception
  try {
     final appLinks = AppLinks();
     
     // Handle initial link
     final initialLink = await appLinks.getInitialLink();
     if (initialLink != null) {
       print('PLATFORM_INIT: Initial Link Received: $initialLink');
       // We can optionally dispatch this if Supabase doesn't catch it
       // final context = navigatorKey.currentContext;
       // if (context != null) context.read<AuthBloc>().add(AuthDeepLinkReceived(initialLink.toString()));
     }

     // Listen to stream
     appLinks.uriLinkStream.listen((uri) {
        print('PLATFORM_INIT: Stream Link Received: $uri');
        final context = navigatorKey.currentContext;
        if (context != null) {
           // Manually feed it to AuthBloc just in case Supabase misses it 
           // (AuthBloc handles deduplication or state checks hopefully)
           context.read<AuthBloc>().add(AuthDeepLinkReceived(uri.toString()));
        }
     }, onError: (err) {
        print('PLATFORM_INIT: Link Stream Error: $err');
     });
        
  } catch (e) {
     print('PLATFORM_INIT: AppLinks Setup Failed: $e');
  }
}
