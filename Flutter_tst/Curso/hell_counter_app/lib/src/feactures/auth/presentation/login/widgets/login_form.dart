// lib/src/features/auth/presentation/login/widgets/login_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hell_counter_app/src/feactures/auth/presentation/login/cubit/login_form_cubit.dart';
import 'package:hell_counter_app/src/feactures/auth/presentation/login/widgets/login_form_control.dart';
import 'package:hell_counter_app/src/feactures/auth/aplications/auth_cubit.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Acceso correcto')));
          // TODO: Navegar a la pantalla principal
          // En lugar de un SnackBar, ahora llamamos a la lógica de negocio.
        } else if (state is AuthFailure) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Error de Autenticación')),
                ],
              ),
              content: Text(state.error),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isLoading = authState is AuthLoading;
          return AbsorbPointer(
            absorbing: isLoading,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        maxHeight: 300,
                      ),
                      child: Image.asset('lib/assets/images/logo_app.png'),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: BlocBuilder<LoginFormCubit, LoginFormState>(
                        builder: (context, loginFormState) {
                          return LoginFormControl(
                            emailController: _emailController,
                            emailFocusNode: _emailFocusNode,
                            passwordController: _passwordController,
                            passwordFocusNode: _passwordFocusNode,
                            onPasswordSubmitted: (_) => _submitForm(),
                            isRememberMeChecked:
                                loginFormState.isRememberMeChecked,
                            onRememberMeChanged: (newValue) {
                              context.read<LoginFormCubit>().toggleRememberMe(
                                newValue ?? false,
                              );
                            },
                            isLoading: isLoading,
                            onSubmit: _submitForm,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
