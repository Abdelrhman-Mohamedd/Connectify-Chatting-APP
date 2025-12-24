import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_messaging_app/core/widgets/custom_button.dart';
import 'package:flutter_messaging_app/core/widgets/custom_text_field.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final password = _passwordController.text.trim();
    if (password.isNotEmpty && password.length >= 6) {
      context.read<AuthBloc>().add(AuthUpdatePasswordRequested(password));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Password')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated successfully!')),
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
              const Text(
                'Enter your new password',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                label: 'New Password',
                hint: 'Enter your new password',
                isPassword: true,
              ),
              const SizedBox(height: 20),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                   return CustomButton(
                    onPressed: _onSubmit,
                    text: 'Update Password',
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
