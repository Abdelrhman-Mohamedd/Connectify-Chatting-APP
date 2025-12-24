import 'package:equatable/equatable.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const AuthSignUpRequested({required this.email, required this.password, this.name});

  @override
  List<Object> get props => [email, password, name ?? ''];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthVerifyEmailRequested extends AuthEvent {
  final String email;
  final String token;

  const AuthVerifyEmailRequested({required this.email, required this.token});

  @override
  List<Object> get props => [email, token];
}

class AuthStateChange extends AuthEvent {
  final AuthState state;
  const AuthStateChange(this.state);
  @override
  List<Object> get props => [state];
}

class AuthUpdatePasswordRequested extends AuthEvent {
  final String password;
  const AuthUpdatePasswordRequested(this.password);
  @override
  List<Object> get props => [password];
}
class AuthUpdateProfileRequested extends AuthEvent {
  final String? name;
  final dynamic imageFile;

  const AuthUpdateProfileRequested({this.name, this.imageFile});

  @override
  List<Object?> get props => [name, imageFile];
}

class AuthDeepLinkReceived extends AuthEvent {
  final String url;
  const AuthDeepLinkReceived(this.url);
  @override
  List<Object> get props => [url];
}
