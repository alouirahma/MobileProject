import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile2025/Screens/login/login_screen.dart';
import 'package:mobile2025/bloc/register/register_bloc.dart';
import 'components/body.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key}); // ← CORRIGÉ

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocProvider(
          create: (context) => RegisterBloc(), // ← BLoC CRÉÉ ICI
          child: BlocListener<RegisterBloc, RegisterState>(
            listener: (context, state) {
              if (state is RegisterFailure) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.error)));
              }
              if (state is RegisterSuccess) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Body(), // ← const OK
          ),
        ),
      ),
    );
  }
}
