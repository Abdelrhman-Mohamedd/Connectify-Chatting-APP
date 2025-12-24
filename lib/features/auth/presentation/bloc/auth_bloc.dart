import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/core/usecases/usecase.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_messaging_app/features/auth/data/models/user_model.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:flutter_messaging_app/core/services/presence_service.dart'; // New
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final VerifyEmailUseCase _verifyEmailUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final PresenceService _presenceService; // New
    late final StreamSubscription<supabase.AuthState> _authSub;

  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required VerifyEmailUseCase verifyEmailUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required PresenceService presenceService, // New
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _verifyEmailUseCase = verifyEmailUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _presenceService = presenceService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
    on<AuthVerifyEmailRequested>(_onAuthVerifyEmailRequested);
    on<AuthStateChange>(_onAuthStateChange);
    on<AuthUpdatePasswordRequested>(_onAuthUpdatePasswordRequested);
    on<AuthDeepLinkReceived>(_onAuthDeepLinkReceived);
    on<AuthUpdateProfileRequested>(_onAuthUpdateProfileRequested);



    _initAuthListener();
  }

  Future<void> _onAuthDeepLinkReceived(
      AuthDeepLinkReceived event, Emitter<AuthState> emit) async {
      try {
        final uri = Uri.parse(event.url);
        
        // Emit recovery state IMMEDIATELY if it looks like a recovery link
        // This ensures proper routing and blocks 'AuthAuthenticated' from overwriting state
        if (uri.authority == 'reset-callback' || uri.path == '/reset-callback' || uri.queryParameters.containsKey('code')) {
           emit(const AuthPasswordRecovery());
        }

        await supabase.Supabase.instance.client.auth.getSessionFromUrl(uri);
        
      } catch (e) {
        emit(AuthError(e.toString()));
      }
  }



  @override
  Future<void> close() {
    _authSub.cancel();
    _presenceService.dispose();
    return super.close();
  }

  void _onAuthStateChange(AuthStateChange event, Emitter<AuthState> emit) {
    if (state is AuthPasswordRecovery && event.state is AuthAuthenticated) {
       return;
    }
    emit(event.state);
  }

  // Helper to initialize listener (moved logic here to use _log)
  void _initAuthListener() {
     _authSub = supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('AuthBloc: Received Auth Event: $event'); 
      if (event == supabase.AuthChangeEvent.passwordRecovery) {
        debugPrint('AuthBloc: Emitting AuthPasswordRecovery');
        add(const AuthStateChange(AuthPasswordRecovery()));
      } else if (event == supabase.AuthChangeEvent.signedIn) {
        debugPrint('AuthBloc: Emitting AuthAuthenticated');
        _presenceService.initialize(); // Track presence
        add(AuthStateChange(AuthAuthenticated(UserModel.fromSupabase(data.session!.user))));
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        debugPrint('AuthBloc: Emitting AuthUnauthenticated');
        add(const AuthStateChange(AuthUnauthenticated()));
      }
    });
  }

  Future<void> _onAuthUpdatePasswordRequested(
      AuthUpdatePasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await supabase.Supabase.instance.client.auth.updateUser(
        supabase.UserAttributes(password: event.password),
      );
      // Requirement: Logout after update so user can sign in manually
      await _signOutUseCase(const NoParams());
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  // ... existing handlers ...
  
  Future<void> _onAuthVerifyEmailRequested(
      AuthVerifyEmailRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _verifyEmailUseCase(
      VerifyEmailParams(email: event.email, token: event.token),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) async {
        final userResult = await _getCurrentUserUseCase(const NoParams());
        userResult.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(AuthAuthenticated(user)),
        );
      }, 
    );
  }
  
  // ... existing handlers ...

  Future<void> _onAuthUpdateProfileRequested(
      AuthUpdateProfileRequested event, Emitter<AuthState> emit) async {
    
    // Capture current user to restore state if needed
    final currentUser = state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
    
    if (currentUser == null) {
      emit(const AuthError('User not logged in'));
      return;
    }

    emit(const AuthLoading()); // This will show loading but unfortunately hide the user momentarily. 
    // Ideally AuthState should be refactored, but to fix "while maintaining functionalities" without big refactors:
    
    final result = await _updateProfileUseCase(
      UpdateProfileParams(name: event.name, imageFile: event.imageFile),
    );
    
    result.fold(
      (failure) {
        emit(AuthError(failure.message));
        // RESTORE THE AUTHENTICATED STATE so the user doesn't look logged out
        emit(AuthAuthenticated(currentUser)); 
      },
      (updatedUser) => emit(AuthAuthenticated(updatedUser)),
    );
  }

  Future<void> _onAuthResetPasswordRequested(
      AuthResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _resetPasswordUseCase(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _signInUseCase(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthSignUpRequested(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _signUpUseCase(
      SignUpParams(
          email: event.email, password: event.password, name: event.name),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _signOutUseCase(const NoParams());
    emit(AuthUnauthenticated());
  }
}
