import 'package:flutter/material.dart';
import '../../../../../../widgets/app_text_field.dart';
import '../../../../../../widgets/primary_button.dart';

class LoginFormControl extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final Function(String) onPasswordSubmitted;
  final bool isRememberMeChecked;
  final Function(bool?) onRememberMeChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  const LoginFormControl({
    super.key,
    required this.emailController,
    required this.emailFocusNode,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.onPasswordSubmitted,
    required this.isRememberMeChecked,
    required this.onRememberMeChanged,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: emailController,
          focusNode: emailFocusNode,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu email';
            }
            if (!value.contains('@')) {
              return 'Por favor ingresa un email válido';
            }
            return null;
          },
          onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          label: 'Contraseña',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 5) {
              return 'La contraseña debe tener al menos 5 caracteres';
            }
            return null;
          },
          onFieldSubmitted: onPasswordSubmitted,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: isRememberMeChecked,
              onChanged: onRememberMeChanged,
            ),
            const Text('Recordarme'),
          ],
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          onPressed: isLoading ? null : onSubmit,
          label: isLoading ? 'Cargando...' : 'Iniciar Sesión',
          isLoading: isLoading,
        ),
      ],
    );
  }
}
