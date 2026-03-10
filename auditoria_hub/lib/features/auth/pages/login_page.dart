// features/auth/pages/login_page.dart
// Rediseño Apple HIG — Red social profesional, glassmorphismo selectivo
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/form_label.dart';
import '../domain/commands/login_command.dart';
import '../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';

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
  bool _showResetLink = false;
  bool _resetSent = false;
  String? _errorMsg;
  Timer? _wakeUpTimer;

  String _detectedRole = '';
  String _lastEmail = '';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
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
    final displayRole =
        (newRole == 'Docente' || newRole == 'Invitado' || newRole == 'SuperAdmin')
            ? newRole
            : (email.isNotEmpty ? 'Invitado' : '');
    if (displayRole != _detectedRole) {
      setState(() => _detectedRole = displayRole);
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
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
      _showResetLink = false;
      _resetSent = false;
    });
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
      if (authState.isFirstLogin) {
        context.go('/register');
      } else {
        context.go('/showcase');
      }
    } else if (authState is AuthError) {
      final msg = authState.message;
      final isCredError = msg.toLowerCase().contains('contraseña') ||
          msg.toLowerCase().contains('incorrectos') ||
          msg.toLowerCase().contains('credential') ||
          msg.toLowerCase().contains('encontrada');
      setState(() {
        _errorMsg = msg;
        _showResetLink = isCredError;
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
      _showResetLink = false;
      _resetSent = false;
    });
    _wakeUpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) setState(() => _showWakeUp = true);
    });

    await ref.read(authStateProvider.notifier).createAccount(
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
      context.go('/register');
    } else if (authState is AuthError) {
      setState(() => _errorMsg = authState.message);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMsg = null;
    });
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await ref.read(authStateProvider.notifier).login(
            LoginCommand(
              email: googleUser.email,
              password: '',
              isGoogleSignIn: true,
            ),
          );

      if (!mounted) return;
      final authState = ref.read(authStateProvider);
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
        setState(
            () => _errorMsg = 'No se pudo iniciar con Google. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
          () => _errorMsg = 'Ingresa tu correo antes de recuperar la contraseña.');
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
      setState(() => _errorMsg = 'No se pudo enviar el correo de recuperación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;

    // Colores adaptativos iOS
    final bgTop = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFF2F2F7);
    final cardColor = isDark ? AppColors.darkSurface1 : Colors.white;
    final primaryBtn = isDark ? Colors.white : AppColors.lightForeground;
    final primaryBtnText = isDark ? AppColors.darkTextInverse : Colors.white;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;

    return Scaffold(
      backgroundColor: bgTop,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header — Identidad de red social ─────────────────────
                SizedBox(
                  height: screenH * 0.30,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Fondo con gradiente sutil tipo iOS
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDark
                                ? [
                                    const Color(0xFF0A0A0A),
                                    const Color(0xFF1C1C1E),
                                  ]
                                : [
                                    const Color(0xFFE8F4FD),
                                    const Color(0xFFF2F2F7),
                                  ],
                          ),
                        ),
                      ),
                      // Orbe decorativo sutil
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isDark
                                        ? AppColors.darkAccent
                                        : AppColors.lightAccent)
                                    .withOpacity(isDark ? 0.08 : 0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isDark
                                        ? AppColors.darkAccent
                                        : AppColors.lightAccent)
                                    .withOpacity(isDark ? 0.05 : 0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Contenido centrado
                      Padding(
                        padding: EdgeInsets.only(top: topPad),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App icon — squircle style
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface2
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark
                                              ? AppColors.darkAccent
                                              : AppColors.lightAccent)
                                          .withOpacity(0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.hub_rounded,
                                  size: 32,
                                  color: isDark
                                      ? AppColors.darkAccent
                                      : AppColors.lightAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Biofrost',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Universidad Tecnológica Metropolitana',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: mutedColor,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Formulario — Card elevada ──────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenH * 0.70),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xxl)),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04), // Lighter, more diffuse shadow
                            blurRadius: 40,
                            offset: const Offset(0, -10),
                          ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 48), // Wider padding for breathing room
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Indicador de arrastre ─────────────────────
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Título
                          Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Accede a tu cuenta de auditoría',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Correo ──────────────────────────────────────
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
                            ),
                            decoration: InputDecoration(
                              hintText: 'correo@institucion.edu',
                              prefixIcon:
                                  Icon(Icons.email_outlined, size: 18, color: mutedColor),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu correo';
                              if (!v.contains('@')) return 'Correo inválido';
                              return null;
                            },
                          ),

                          // ── Badge de rol detectado ─────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _detectedRole.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _RoleBadge(
                                      role: _detectedRole,
                                      isDark: isDark,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 16),

                          // ── Contraseña ──────────────────────────────────
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
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tu contraseña',
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  size: 18, color: mutedColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: mutedColor,
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

                          // ── Mensajes ────────────────────────────────────
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 16),
                            _AlertBanner(
                              color: AppColors.error,
                              icon: Icons.error_outline_rounded,
                              message: _errorMsg!,
                            ),
                            if (_showResetLink) ...[
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _sendPasswordReset,
                                child: Text(
                                  '¿Olvidaste tu contraseña? Recupérala aquí',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.lightAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (_resetSent) ...[
                            const SizedBox(height: 16),
                            _AlertBanner(
                              color: AppColors.success,
                              icon: Icons.check_circle_outline_rounded,
                              message:
                                  'Correo de recuperación enviado. Revisa tu bandeja.',
                            ),
                          ],
                          if (_showWakeUp) ...[
                            const SizedBox(height: 12),
                            _AlertBanner(
                              color: AppColors.warning,
                              icon: Icons.hourglass_top_rounded,
                              message:
                                  'Servidor despertando… Esto solo ocurre en la primera conexión del día.',
                              showSpinner: true,
                            ),
                          ],

                          const SizedBox(height: 28),

                          // ── CTA Principal — Iniciar Sesión ─────────────
                          _ApplePrimaryButton(
                            label: 'Iniciar Sesión',
                            isLoading: _isLoading,
                            onPressed: _isLoading || _isGoogleLoading
                                ? null
                                : _submitLogin,
                            bgColor: primaryBtn,
                            fgColor: primaryBtnText,
                          ),

                          const SizedBox(height: 10),

                          // ── Secundario — Crear Cuenta ──────────────────
                          _AppleOutlineButton(
                            label: 'Crear cuenta nueva',
                            isLoading: _isLoading,
                            onPressed: _isLoading || _isGoogleLoading
                                ? null
                                : _createAccount,
                            isDark: isDark,
                          ),

                          // ── Divisor ─────────────────────────────────────
                          const SizedBox(height: 24),
                          _LightDivider(isDark: isDark),
                          const SizedBox(height: 20),

                          // ── Google Button ───────────────────────────────
                          _GoogleButton(
                            isLoading: _isGoogleLoading,
                            onPressed: _isLoading || _isGoogleLoading
                                ? null
                                : _signInWithGoogle,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge de rol ──────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isDark});
  final String role;
  final bool isDark;

  Color get _bgColor => switch (role) {
        'Docente' => isDark
            ? const Color(0xFF0A2F1A)
            : const Color(0xFFE6F9ED),
        'SuperAdmin' => isDark
            ? const Color(0xFF1A0F00)
            : const Color(0xFFFFF3E0),
        _ => isDark
            ? const Color(0xFF001A3D)
            : const Color(0xFFE8F4FD),
      };

  Color get _fgColor => switch (role) {
        'Docente' => isDark ? const Color(0xFF30D158) : const Color(0xFF1A7A35),
        'SuperAdmin' =>
          isDark ? const Color(0xFFFF9F0A) : const Color(0xFFB06000),
        _ => isDark ? const Color(0xFF0A84FF) : const Color(0xFF0062CC),
      };

  IconData get _icon => switch (role) {
        'Docente' => Icons.school_rounded,
        'SuperAdmin' => Icons.admin_panel_settings_rounded,
        _ => Icons.person_outline_rounded,
      };

  String get _label => switch (role) {
        'Docente' => 'Docente UTM — acceso al panel de enseñanza',
        'SuperAdmin' => 'Administrador — acceso total al sistema',
        _ => 'Invitado — acceso externo con permisos limitados',
      };

  String get _roleTag => switch (role) {
        'Docente' => 'Docente',
        'SuperAdmin' => 'Super Admin',
        _ => 'Invitado',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: _fgColor.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _fgColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 14, color: _fgColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rol detectado: $_roleTag',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _fgColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: _fgColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón Primary Apple ───────────────────────────────────────────────────────

class _ApplePrimaryButton extends StatelessWidget {
  const _ApplePrimaryButton({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final Color bgColor;
  final Color fgColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: fgColor),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: fgColor,
                ),
              ),
      ),
    );
  }
}

// ── Botón Outline Apple ───────────────────────────────────────────────────────

class _AppleOutlineButton extends StatelessWidget {
  const _AppleOutlineButton({
    required this.label,
    required this.isDark,
    this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final bool isDark;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final border =
        isDark ? AppColors.darkBorder : const Color(0xFFD1D1D6);

    return SizedBox(
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border, width: 1.0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
          backgroundColor:
              isDark ? AppColors.darkSurface2.withOpacity(0.5) : Colors.transparent,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: text),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: text,
                  letterSpacing: -0.2,
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
    final lineColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA);
    final textColor =
        isDark ? AppColors.darkTextDisabled : AppColors.lightMutedFg;

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
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA);
    final bgColor = isDark ? AppColors.darkSurface2 : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;

    return SizedBox(
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
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: textColor),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://w7.pngwing.com/pngs/326/85/png-transparent-google-logo-google-text-trademark-logo-thumbnail.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.g_mobiledata_rounded,
                      size: 24,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
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
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: color),
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
