// lib/src/features/auth/presentation/login/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hell_counter_app/src/feactures/auth/presentation/login/widgets/login_form.dart';
import 'package:hell_counter_app/src/feactures/auth/presentation/login/cubit/login_form_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginFormCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: const LoginForm(),
      ),
    );
  }
}
