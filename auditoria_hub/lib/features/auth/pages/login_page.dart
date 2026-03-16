// features/auth/pages/login_page.dart
// Rediseño Apple HIG — Red social profesional, glassmorphismo selectivo
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/ui/animations/scale_on_tap_wrapper.dart';
import '../../../core/ui/buttons/animated_action_button.dart';
import '../../../core/ui/feedback/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/form_label.dart';
import '../domain/commands/login_command.dart';
import '../domain/models/auth_state.dart';
import '../presentation/controllers/login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showWakeUp = false;
  bool _resetSent = false;
  String? _errorMsg;
  Timer? _wakeUpTimer;

  String _detectedRole = '';
  String _lastEmail = '';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late LoginController _loginController;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    _loginController = LoginController(ref);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  void _onEmailChanged() {
    final email = _emailCtrl.text;
    if (email == _lastEmail) return;
    _lastEmail = email;
    final newRole = email.isEmpty ? '' : RoleDetector.fromEmail(email);
    if (newRole != _detectedRole) {
      setState(() => _detectedRole = newRole);
    }
  }

  @override
  void dispose() {
    _wakeUpTimer?.cancel();
    _emailCtrl.removeListener(_onEmailChanged);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    await HapticService.lightImpact();
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
      _resetSent = false;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showSheet = _detectedRole.isNotEmpty && _detectedRole != 'Invitado';
    if (showSheet) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _LoginRoleSheet(role: _detectedRole, isDark: isDark),
      );
    }

    _wakeUpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) setState(() => _showWakeUp = true);
    });

    final authState = await _loginController.loginWithEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    _wakeUpTimer?.cancel();
    if (!mounted) return;
    if (showSheet) Navigator.of(context).pop();

    setState(() {
      _isLoading = false;
      _showWakeUp = false;
    });

    if (authState is AuthAuthenticated) {
      await HapticService.success();
      if (authState.isFirstLogin) {
        context.go('/register');
      } else {
        context.go('/showcase');
      }
    } else if (authState is AuthError) {
      setState(() => _errorMsg = authState.message);
    }
  }

  Future<void> _signInWithGoogle() async {
    await HapticService.lightImpact();
    setState(() {
      _isGoogleLoading = true;
      _errorMsg = null;
    });
    try {
      final authState = await _loginController.loginWithGoogle(
        googleSignIn: GoogleSignIn(),
        firebaseAuth: FirebaseAuth.instance,
      );

      if (!mounted) return;
      if (authState is AuthLoading || authState is AuthUnauthenticated) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      if (authState is AuthAuthenticated) {
        if (authState.isFirstLogin) {
          context.go('/register');
        } else {
          context.go('/showcase');
        }
      } else if (authState is AuthError) {
        setState(() => _errorMsg = authState.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMsg = 'No se pudo iniciar con Google. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    await HapticService.lightImpact();
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() =>
          _errorMsg = 'Ingresa tu correo antes de recuperar la contraseña.');
      return;
    }
    try {
      await _loginController.sendPasswordReset(email);
      await HapticService.success();
      setState(() {
        _resetSent = true;
        _errorMsg = null;
      });
    } catch (_) {
      setState(
          () => _errorMsg = 'No se pudo enviar el correo de recuperación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkSurface0 : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final borderSoft = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightOlive;

    return Scaffold(
      backgroundColor: pageBg,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Header / identidad
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(isDark ? 0.12 : 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.hub_rounded,
                            size: 24,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Biofrost',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Universidad Tecnológica Metropolitana',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Completa tus datos para registrarte',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  FormLabel('Correo electrónico', isDark: isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          isDark ? AppColors.darkSurface2 : AppColors.lightCard,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderSoft),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accent, width: 1.3),
                      ),
                      hintText: 'correo@institucion.edu',
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: textSecondary,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FormLabel('Contraseña', isDark: isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          isDark ? AppColors.darkSurface2 : AppColors.lightCard,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderSoft),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accent, width: 1.3),
                      ),
                      hintText: 'Tu contraseña',
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitLogin(),
                  ),

                  // ── ¿Olvidaste tu contraseña? ────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _sendPasswordReset,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // ── Mensajes ─────────────────────────────────────────
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 8),
                    _AlertBanner(
                      color: AppColors.error,
                      icon: Icons.error_outline_rounded,
                      message: _errorMsg!,
                    ),
                  ],
                  if (_resetSent) ...[
                    const SizedBox(height: 8),
                    _AlertBanner(
                      color: AppColors.lightPrimary,
                      icon: Icons.check_circle_outline_rounded,
                      message:
                          'Correo de recuperación enviado. Revisa tu bandeja.',
                    ),
                  ],
                  if (_showWakeUp) ...[
                    const SizedBox(height: 8),
                    _AlertBanner(
                      color: AppColors.lightOlive,
                      icon: Icons.hourglass_top_rounded,
                      message:
                          'Servidor despertando… Esto solo ocurre en la primera conexión del día.',
                      showSpinner: true,
                    ),
                  ],

                  const SizedBox(height: 28),

                  AnimatedActionButton(
                    label: 'Iniciar Sesión',
                    isLoading: _isLoading,
                    onPressed:
                        _isLoading || _isGoogleLoading ? null : _submitLogin,
                    backgroundColor:
                      isDark ? AppColors.darkAccent : AppColors.lightForeground,
                    foregroundColor:
                      isDark ? AppColors.darkTextInverse : AppColors.lightCard,
                  ),

                  const SizedBox(height: 20),

                  // ── Divisor ──────────────────────────────────────────
                  _LightDivider(isDark: isDark),

                  const SizedBox(height: 20),

                  // ── Continuar con Google ─────────────────────────────
                  _GoogleButton(
                    isDark: isDark,
                    isLoading: _isGoogleLoading,
                    onPressed: _isLoading || _isGoogleLoading
                        ? null
                        : _signInWithGoogle,
                  ),

                  const SizedBox(height: 28),

                  // ── ¿No tienes cuenta? ───────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading || _isGoogleLoading
                            ? null
                            : () => context.push('/create-account'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Crear una nueva',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Login Role Sheet — confirmación post-submit ──────────────────────────────

class _LoginRoleSheet extends StatelessWidget {
  const _LoginRoleSheet({required this.role, required this.isDark});
  final String role;
  final bool isDark;

  IconData get _icon => switch (role) {
        'Alumno' => Icons.school_rounded,
        'Docente' => Icons.school_rounded,
        'SuperAdmin' => Icons.admin_panel_settings_rounded,
        _ => Icons.person_outline_rounded,
      };

  String get _label => switch (role) {
        'Alumno' => 'Entrando como Alumno UTM',
        'Docente' => 'Entrando como Docente UTM',
        'SuperAdmin' => 'Acceso de Administrador',
        _ => 'Iniciando sesión',
      };

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightOlive;
    final surface = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final textPrimary =
      isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final textSecondary =
      isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 26, color: accent),
              ),
              const SizedBox(height: 14),
              Text(
                _label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verificando credenciales...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: accent.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Divisor ligero ───────────────────────────────────────────────────────────

class _LightDivider extends StatelessWidget {
  const _LightDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 0.5, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: textColor,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 0.5, height: 1)),
      ],
    );
  }
}

// ── Botón Google ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.isDark,
    this.onPressed,
    this.isLoading = false,
  });
  final bool isDark;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;

    return ScaleOnTapWrapper(
      enabled: !isLoading && onPressed != null,
      child: SizedBox(
        height: 54,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: bgColor,
            side: BorderSide(color: borderColor, width: 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://w7.pngwing.com/pngs/326/85/png-transparent-google-logo-google-text-trademark-logo-thumbnail.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 24,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Continuar con Google',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Alert Banner ─────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.color,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });
  final Color color;
  final IconData icon;
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSpinner)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
