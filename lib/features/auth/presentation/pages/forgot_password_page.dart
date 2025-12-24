import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/core/widgets/custom_button.dart';
import 'package:flutter_messaging_app/core/widgets/custom_text_field.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.read<AuthBloc>().add(AuthResetPasswordRequested(email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password reset link sent! Check your email.')),
            );
            context.pop(); // Go back to login
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
              const Text(
                'Enter your email address',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                isPassword: false,
              ),
              const SizedBox(height: 20),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                   return CustomButton(
                    onPressed: _onSubmit,
                    text: 'Send Reset Link',
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
