// features/auth/pages/login_page.dart — RF-01: Login/Registro estilo Biofrost
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
  final _orgCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMsg;

  // Invitado = cualquier correo que NO sea de la institución
  bool get _isGuest =>
      !_emailCtrl.text.trim().toLowerCase().endsWith('@utmetropolitana.edu.mx');

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    await ref.read(authStateProvider.notifier).login(
          LoginCommand(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          ),
        );
    final authState = ref.read(authStateProvider);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (authState is AuthAuthenticated) {
      // Notificación de éxito tipo 10.svg
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
      // Diferenciar errores para dar un mensaje claro al usuario
      if (msg.contains('NetworkException') || msg.contains('network')) {
        setState(() => _errorMsg =
            'Sin conexión. Verifica tu internet e intenta de nuevo.');
      } else if (msg.contains('TimeoutException') || msg.contains('timeout')) {
        setState(() => _errorMsg =
            'El servidor tardó en responder (primera conexión del día). Espera unos segundos e intenta de nuevo.');
      } else {
        setState(() => _errorMsg = msg);
      }
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
                        // ── Organización — solo visible para invitados ────
                        if (_isGuest) ...[
                          const SizedBox(height: 18),
                          _FieldLabel('Organización', isDark: isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _orgCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Nombre de tu organización',
                              prefixIcon:
                                  Icon(Icons.business_outlined, size: 18),
                            ),
                            onFieldSubmitted: (_) => _submitLogin(),
                          ),
                        ],
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
                        ],
                        const SizedBox(height: 28),
                        // Aviso de cold-start cuando el servidor puede estar dormido
                        if (_isLoading) ...[
                          const SizedBox(height: 8),
                          Text(
                            'La primera conexión del día puede tardar hasta 60 s mientras el servidor despierta.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightMutedFg,
                            ),
                          ),
                        ],
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
