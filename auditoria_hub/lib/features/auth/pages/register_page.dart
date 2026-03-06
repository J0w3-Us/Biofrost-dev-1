// features/auth/pages/register_page.dart — Pantalla de registro (diseño profesional)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../domain/commands/login_command.dart';
import '../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';

Color _getRoleColor(String role) {
  return switch (role) {
    'Docente' => const Color(0xFF2563EB),
    'Alumno' => const Color(0xFF16A34A),
    'SuperAdmin' => const Color(0xFFDC2626),
    _ => const Color(0xFF9333EA), // Invitado
  };
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _apellidoPaternoCtrl = TextEditingController();
  final _apellidoMaternoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _profesionCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  // Detectar rol en tiempo real
  String get _detectedRole => RoleDetector.fromEmail(_emailCtrl.text);
  bool get _isGuest => _detectedRole == 'Invitado';
  bool get _isTeacher => _detectedRole == 'Docente';

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _orgCtrl.dispose();
    _profesionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final cmd = RegisterCommand(
        nombre: _nameCtrl.text.trim(),
        apellidoPaterno: _apellidoPaternoCtrl.text.trim().isNotEmpty
            ? _apellidoPaternoCtrl.text.trim()
            : null,
        apellidoMaterno: _apellidoMaternoCtrl.text.trim().isNotEmpty
            ? _apellidoMaternoCtrl.text.trim()
            : null,
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        rol: _detectedRole,
        profesion: _isTeacher && _profesionCtrl.text.trim().isNotEmpty
            ? _profesionCtrl.text.trim()
            : null,
        organizacion: _isGuest && _orgCtrl.text.trim().isNotEmpty
            ? _orgCtrl.text.trim()
            : null,
        carrerasIds: const [],
        gruposDocente: const [],
      );

      await ref.read(authStateProvider.notifier).register(cmd);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Verificar si el registro fue exitoso
      final authState = ref.read(authStateProvider);
      if (authState is AuthError) {
        setState(() => _errorMsg = authState.message);
        return;
      }

      // Notificación de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RegisterSuccessDialog(
          name: _nameCtrl.text.trim(),
          role: _detectedRole,
          onClose: () => context.go('/login'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Banner imagen responsivo con botón atrás ─────────────────
              SizedBox(
                height: screenH * 0.28,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/banner/Gemini_Generated_Image_wzcsrgwzcsrgwzcs.png',
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withOpacity(0.48)),
                    // Botón atrás sobre la imagen
                    Positioned(
                      top: topPad + 12,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    // Título centrado
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Auditoría Hub · UTM',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Formulario — sin bordes, full-width ─────────────────────
              Container(
                color: isDark ? AppColors.darkSurface1 : Colors.white,
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Nombre ──────────────────────────────────────────
                      _FieldLabel('Nombre *', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Tu nombre',
                          prefixIcon:
                              Icon(Icons.person_outline_rounded, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Apellido Paterno ────────────────────────────────
                      _FieldLabel('Apellido Paterno', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _apellidoPaternoCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Apellido paterno (opcional)',
                          prefixIcon: Icon(Icons.person_2_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Apellido Materno ────────────────────────────────
                      _FieldLabel('Apellido Materno', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _apellidoMaternoCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Apellido materno (opcional)',
                          prefixIcon: Icon(Icons.person_3_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Correo ──────────────────────────────────────────
                      _FieldLabel('Correo electrónico *', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'correo@institucion.edu',
                          prefixIcon:
                              const Icon(Icons.email_outlined, size: 18),
                          suffixIcon: _emailCtrl.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(_detectedRole)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _getRoleColor(_detectedRole)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _detectedRole,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: _getRoleColor(_detectedRole),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Ingresa tu correo';
                          if (!v.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Profesión — solo Docentes ────────────────────────
                      if (_isTeacher) ...[
                        _FieldLabel('Profesión', isDark: isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _profesionCtrl,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Ej: Ingeniero en Sistemas',
                            prefixIcon:
                                Icon(Icons.work_outline_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Contraseña ───────────────────────────────────────
                      _FieldLabel('Contraseña *', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Mínimo 6 caracteres',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 18),
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
                            return 'Ingresa una contraseña';
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Confirmar contraseña ─────────────────────────────
                      _FieldLabel('Confirmar contraseña *', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Repite tu contraseña',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passCtrl.text)
                            return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Organización — solo invitados ─────────────────────
                      if (_isGuest) ...[
                        _FieldLabel('Organización', isDark: isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _orgCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'Institución u organización (opcional)',
                            prefixIcon: Icon(Icons.business_outlined, size: 18),
                          ),
                          onFieldSubmitted: (_) => _submitRegister(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Error ────────────────────────────────────────
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
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),
                      BioButton(
                        label: 'Crear cuenta',
                        isLoading: _isLoading,
                        onPressed: _submitRegister,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

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

// ── Diálogo de éxito de registro — inspirado en 10.svg ─────────────────────

class _RegisterSuccessDialog extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onClose;
  const _RegisterSuccessDialog({
    required this.name,
    required this.role,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final first = name.isNotEmpty ? name.split(' ').first : 'nuevo usuario';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de celebración
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Cuenta creada!',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenido, $first.\nYa puedes iniciar sesión con tus credenciales.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightMutedFg,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            BioButton(label: 'Ir a inicio de sesión', onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
