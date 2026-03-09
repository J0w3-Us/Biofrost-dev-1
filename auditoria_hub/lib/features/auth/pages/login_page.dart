// features/auth/pages/login_page.dart — RF-01: Login/Registro estilo Biofrost
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/commands/login_command.dart';
import '../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';

/// LoginPage — Rediseño profesional sin efectos neon, inspirado en 3.svg
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _showWakeUp = false;
  bool _showResetLink = false;
  bool _resetSent = false;
  String? _errorMsg;
  Timer? _wakeUpTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _wakeUpTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
      _showResetLink = false;
      _resetSent = false;
    });
    // Mostrar aviso de wake-up si el servidor tarda más de 8 s
    _wakeUpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) setState(() => _showWakeUp = true);
    });
    await ref.read(authStateProvider.notifier).login(
          LoginCommand(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          ),
        );
    _wakeUpTimer?.cancel();
    final authState = ref.read(authStateProvider);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showWakeUp = false;
    });
    if (authState is AuthAuthenticated) {
      showDialog(
        context: context,
        builder: (_) => _SuccessDialog(
          title: '¡Bienvenido!',
          message: 'Inicio de sesión exitoso.',
          onClose: () => context.go('/showcase'),
        ),
        barrierDismissible: false,
      );
    } else if (authState is AuthError) {
      final msg = authState.message;
      final isCredError = msg.toLowerCase().contains('contraseña') ||
          msg.toLowerCase().contains('incorrectos') ||
          msg.toLowerCase().contains('credential');
      setState(() {
        _errorMsg = msg;
        _showResetLink = isCredError;
      });
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Ingresa tu correo antes de recuperar la contraseña.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _resetSent = true;
        _showResetLink = false;
        _errorMsg = null;
      });
    } catch (_) {
      setState(() => _errorMsg = 'No se pudo enviar el correo de recuperación. Verifica el correo e intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Banner imagen — altura responsiva ─────────────────────
              SizedBox(
                height: screenH * 0.36,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/banner/Gemini_Generated_Image_wzcsrgwzcsrgwzcs.png',
                      fit: BoxFit.cover,
                    ),
                    // Overlay para legibilidad
                    Container(color: Colors.black.withOpacity(0.45)),
                    // Texto centrado sobre la imagen
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Biofrost',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Universidad Tecnológica Metropolitana',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.90),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Formulario — sin bordes, full-width, llena el resto ──
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenH * 0.64),
                child: Container(
                  color: isDark ? AppColors.darkSurface1 : Colors.white,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightForeground,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FieldLabel('Correo', isDark: isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'correo@institucion.edu',
                            prefixIcon: Icon(Icons.email_outlined, size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Ingresa tu correo';
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel('Contraseña', isDark: isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Tu contraseña',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Ingresa tu contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                          onFieldSubmitted: (_) => _submitLogin(),
                        ),

                        if (_errorMsg != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: AppColors.error.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 16, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMsg!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.error)),
                                ),
                              ],
                            ),
                          ),
                          if (_showResetLink) ...[  
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: _sendPasswordReset,
                              child: const Text('¿Olvidaste tu contraseña? Recúpérala aquí'),
                            ),
                          ],
                        ],
                        if (_resetSent) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: Colors.green.withAlpha(80)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 16, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Correo de recuperación enviado. Revisa tu bandeja.',
                                    style: TextStyle(fontSize: 13, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_showWakeUp) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border:
                                  Border.all(color: Colors.orange.withAlpha(80)),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.orange),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Servidor despertando... Esto solo ocurre en la primera conexión del día.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        BioButton(
                          label: 'Iniciar sesión',
                          isLoading: _isLoading,
                          onPressed: _submitLogin,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('¿No tienes cuenta? Regístrate'),
                        ),
                      ],
                    ),
                  ),
                ), // Container
              ), // ConstrainedBox
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper de etiqueta de campo ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg,
      ),
    );
  }
}

/// Diálogo de éxito tipo 10.svg
class _SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;
  const _SuccessDialog(
      {required this.title, required this.message, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
            const SizedBox(height: 18),
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            BioButton(label: 'Continuar', onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
