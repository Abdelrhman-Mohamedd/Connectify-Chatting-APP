import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/core/widgets/custom_button.dart';
import 'package:flutter_messaging_app/core/widgets/custom_text_field.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      context.read<AuthBloc>().add(
            AuthVerifyEmailRequested(email: widget.email, token: code),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email Verified! Logging in...')),
            );
            context.go('/');
          } else if (state is AuthError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                'Enter the 6-digit code sent to ${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _codeController,
                label: 'Code',
                hint: 'Enter verification code',
                isPassword: false,
              ),
              const SizedBox(height: 20),
               BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return CustomButton(
                    onPressed: _onSubmit,
                    text: 'Verify',
                    isLoading: state is AuthLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
