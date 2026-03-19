// features/auth/pages/create_account_page.dart
// Flujo de registro unificado — Steps: 0=Credenciales 1=Datos 2=Académico 3=Confirmación
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/feedback/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/form_label.dart';
import '../../../core/widgets/micro_interactions.dart';
import '../domain/commands/login_command.dart';
import '../domain/models/auth_state.dart';
import '../presentation/controllers/create_account_controller.dart';
import '../providers/auth_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage>
    with TickerProviderStateMixin {
  // ── Step 0 controllers ────────────────────────────────────────────────
  final _credFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _detectedRole = '';
  String _lastEmail = '';

  // ── Step 1+ controllers ───────────────────────────────────────────────
  final _profileFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _apellidoPaternoCtrl = TextEditingController();
  final _apellidoMaternoCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  String? _selectedCarreraId;
  String? _selectedMateriaId;
  List<String> _selectedGruposIds = [];

  // ── Shared state ──────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _showWakeUp = false;
  String? _errorMsg;
  Timer? _wakeUpTimer;
  int _step = 0;
  bool _startedFromGoogle = false;

  // ── Animations ────────────────────────────────────────────────────────
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late CreateAccountController _createAccountController;

  static const _staggerCount = 6;

  // ── Computed helpers ──────────────────────────────────────────────────
  bool get _isGuest => _detectedRole == 'Invitado';
  bool get _isTeacher => _detectedRole == 'Docente';
  bool get _isAlumno => _detectedRole == 'Alumno';
  bool get _hasAcademicStep => _isTeacher || _isAlumno;
  int get _totalSteps => _hasAcademicStep ? 3 : 2;

  String get _firebaseUid {
    final s = ref.read(authStateProvider);
    if (s is AuthAuthenticated) return s.uid;
    return '';
  }

  void _buildStaggerAnims() {
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnims = List.generate(_staggerCount, (i) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _slideAnims = List.generate(_staggerCount, (i) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    _createAccountController = CreateAccountController(ref);
    _buildStaggerAnims();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkScale = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);

    // Si ya estamos autenticados (ej. por Google), saltamos al step 1 directamente
    final authState = ref.read(authStateProvider);
    if (authState is AuthAuthenticated) {
      _step = 1;
      _startedFromGoogle = true;
      _emailCtrl.text = authState.email;
      _lastEmail = authState.email;
      _detectedRole = 'Invitado'; // Forzado a Invitado como se solicitó
    }
  }

  void _onEmailChanged() {
    final email = _emailCtrl.text;
    if (email == _lastEmail) return;
    _lastEmail = email;
    final role = email.isEmpty ? '' : RoleDetector.fromEmail(email);
    if (role != _detectedRole) setState(() => _detectedRole = role);
  }

  void _advanceStep(int next) {
    HapticFeedback.lightImpact();
    setState(() {
      _step = next;
      _errorMsg = null;
    });
    _staggerCtrl.reset();
    _staggerCtrl.forward();
    if (next == 3) {
      HapticFeedback.selectionClick();
      _checkCtrl.reset();
      _checkCtrl.forward();
    }
  }

  @override
  void dispose() {
    _wakeUpTimer?.cancel();
    _emailCtrl.removeListener(_onEmailChanged);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _orgCtrl.dispose();
    _staggerCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  // ── Step 0: crear cuenta en Firebase ─────────────────────────────────
  Future<void> _submitCredentials() async {
    await HapticService.lightImpact();
    if (!_credFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
    });
    _wakeUpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) setState(() => _showWakeUp = true);
    });

    final authState = await _createAccountController.createAccount(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    _wakeUpTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showWakeUp = false;
    });

    if (authState is AuthAuthenticated) {
      _advanceStep(1);
    } else if (authState is AuthError) {
      setState(() => _errorMsg = authState.message);
    }
  }

  // ── Step 1/2: completar perfil en el backend ─────────────────────────
  Future<void> _submitProfile() async {
    await HapticService.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
    });
    _wakeUpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) setState(() => _showWakeUp = true);
    });

    try {
      final authState = await _createAccountController.completeProfile(
        firebaseUid: _firebaseUid,
        nombre: _nameCtrl.text.trim(),
        apellidoPaterno: _apellidoPaternoCtrl.text.trim().isNotEmpty
            ? _apellidoPaternoCtrl.text.trim()
            : null,
        apellidoMaterno: _apellidoMaternoCtrl.text.trim().isNotEmpty
            ? _apellidoMaternoCtrl.text.trim()
            : null,
        email: _emailCtrl.text.trim(),
        rol: _detectedRole.isEmpty ? 'Invitado' : _detectedRole,
        organizacion: _isGuest && _orgCtrl.text.trim().isNotEmpty
            ? _orgCtrl.text.trim()
            : null,
        asignaciones: _isTeacher &&
                _selectedCarreraId != null &&
                _selectedMateriaId != null
            ? [
                DocenteAsignacion(
                  carreraId: _selectedCarreraId!,
                  materiaId: _selectedMateriaId!,
                  gruposIds: _selectedGruposIds,
                ),
              ]
            : const [],
      );
      if (!mounted) return;
      _wakeUpTimer?.cancel();
      setState(() {
        _isLoading = false;
        _showWakeUp = false;
      });

      if (authState is AuthError) {
        setState(() => _errorMsg = authState.message);
        return;
      }
      await HapticService.success();
      _advanceStep(3);
    } catch (e) {
      if (!mounted) return;
      _wakeUpTimer?.cancel();
      setState(() {
        _isLoading = false;
        _showWakeUp = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> _gruposDeMateria(
      List<Map<String, dynamic>> materias) {
    if (_selectedMateriaId == null) return [];
    for (final entry in materias) {
      final mat = entry['materia'] as Map<String, dynamic>?;
      if (mat?['id'] == _selectedMateriaId) {
        return (entry['gruposDisponibles'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  Future<T?> _showSelectorSheet<T>({
    required BuildContext ctx,
    required String title,
    required List<Map<String, dynamic>> items,
    required T? selected,
    required String Function(Map<String, dynamic>) labelOf,
    String? Function(Map<String, dynamic>)? subtitleOf,
    required T Function(Map<String, dynamic>) valueOf,
  }) {
    return showModalBottomSheet<T>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SelectorSheet<T>(
        title: title,
        items: items,
        selected: selected,
        labelOf: labelOf,
        subtitleOf: subtitleOf,
        valueOf: valueOf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    Widget stagger(int i, Widget child) => FadeTransition(
          opacity: _fadeAnims[i.clamp(0, _staggerCount - 1)],
          child: SlideTransition(
            position: _slideAnims[i.clamp(0, _staggerCount - 1)],
            child: child,
          ),
        );

    return PopScope(
      canPop: _step == 0 || (_startedFromGoogle && _step == 1),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (_startedFromGoogle) {
            ref.read(authStateProvider.notifier).logout();
          }
          return;
        }
        if (_step > 0 && _step < 3) {
          setState(() {
            _step--;
            _errorMsg = null;
          });
          _staggerCtrl.reset();
          _staggerCtrl.forward();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkSurface0 : AppColors.lightBackground,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Step header (pills) ────────────────────────────────
              if (_step > 0 && _step < 3)
                _StepHeader(
                  step: _step,
                  totalSteps: _totalSteps,
                  isDark: isDark,
                  accent: accent,
                  onBack: () {
                    if (_startedFromGoogle && _step == 1) {
                      ref.read(authStateProvider.notifier).logout();
                      if (context.canPop()) context.pop();
                      return;
                    }
                    setState(() {
                      _step--;
                      _errorMsg = null;
                    });
                    _staggerCtrl.reset();
                    _staggerCtrl.forward();
                  },
                ),

              // ── Step content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(isDark, accent, stagger),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    bool isDark,
    Color accent,
    Widget Function(int, Widget) stagger,
  ) {
    switch (_step) {
      case 0:
        return _buildStep0(isDark, accent, stagger);
      case 1:
        return _buildStep1(isDark, accent, stagger);
      case 2:
        return _buildStep2(isDark, accent, stagger);
      case 3:
        return _buildStep3(isDark, accent, stagger);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Credenciales ──────────────────────────────────────────────
  Widget _buildStep0(
      bool isDark, Color accent, Widget Function(int, Widget) stagger) {
    final primaryBtn =
        isDark ? AppColors.darkPrimary : AppColors.lightForeground;
    final primaryBtnText =
        isDark ? AppColors.darkTextInverse : AppColors.lightCard;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;

    return Form(
      key: _credFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // ── Botón volver ────────────────────────────────────────
          stagger(
            0,
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: textPrimary),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/login'),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Brand ────────────────────────────────────────────────
          stagger(
            1,
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkSurface2 : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.hub_rounded, size: 24, color: accent),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Crear cuenta',
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
                    'Completa tus datos para registrarte',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 13, color: mutedColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Correo + chip rol ─────────────────────────────────────
          stagger(
            2,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormLabel('Correo electrónico', isDark: isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'correo@institucion.edu',
                    prefixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _detectedRole == 'Docente' ||
                                _detectedRole == 'SuperAdmin'
                            ? Icons.school_rounded
                            : _detectedRole == 'Alumno'
                                ? Icons.person_rounded
                                : Icons.email_outlined,
                        key: ValueKey(_detectedRole),
                        size: 18,
                        color: _detectedRole.isNotEmpty &&
                                _detectedRole != 'Invitado'
                            ? accent
                            : mutedColor,
                      ),
                    ),
                    suffixIcon: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: _detectedRole.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                  border: Border.all(
                                      color: accent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_roleIcon(_detectedRole),
                                        size: 11, color: accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      _roleLabel(_detectedRole),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Contraseña ────────────────────────────────────────────
          stagger(
            3,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormLabel('Contraseña', isDark: isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Mínimo 6 caracteres',
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
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Confirmar contraseña ──────────────────────────────────
          stagger(
            4,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormLabel('Confirmar contraseña', isDark: isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Repite tu contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        size: 18, color: mutedColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: mutedColor,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                    if (v != _passCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submitCredentials(),
                ),
              ],
            ),
          ),

          // ── Banners ───────────────────────────────────────────────
          if (_errorMsg != null) ...[
            const SizedBox(height: 8),
            _AlertBanner(
              color: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: _errorMsg!,
            ),
          ],
          if (_showWakeUp) ...[
            const SizedBox(height: 8),
            const _AlertBanner(
              color: AppColors.warning,
              icon: Icons.hourglass_top_rounded,
              message:
                  'Servidor despertando… Esto solo ocurre en la primera conexión del día.',
              showSpinner: true,
            ),
          ],
          const SizedBox(height: 28),

          // ── CTA + link ────────────────────────────────────────────
          stagger(
            5,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 54,
                  child: PressScale(
                    enabled: !_isLoading,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBtn,
                        foregroundColor: primaryBtnText,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full)),
                      ),
                      onPressed: _isLoading ? null : _submitCredentials,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: primaryBtnText),
                            )
                          : Text(
                              'Continuar',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: primaryBtnText,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes una cuenta?',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 14, color: mutedColor),
                    ),
                    TextButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  // ── Step 1: Datos personales ──────────────────────────────────────────
  Widget _buildStep1(
      bool isDark, Color accent, Widget Function(int, Widget) stagger) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final primaryBtn =
        isDark ? AppColors.darkPrimary : AppColors.lightForeground;
    final primaryBtnText =
        isDark ? AppColors.darkTextInverse : AppColors.lightCard;

    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Nombre
          stagger(
            0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormLabel('Nombre *', isDark: isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15, color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Apellidos
          stagger(
            1,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormLabel('Ap. Paterno', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _apellidoPaternoCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Paterno',
                          prefixIcon: Icon(Icons.person_2_outlined, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormLabel('Ap. Materno', isDark: isDark),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _apellidoMaternoCtrl,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Materno',
                          prefixIcon: Icon(Icons.person_3_outlined, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Organización (solo invitados)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _isGuest
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: stagger(
                      2,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FormLabel('Organización', isDark: isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _orgCtrl,
                            textInputAction: TextInputAction.done,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Institución u organización (opcional)',
                              prefixIcon:
                                  Icon(Icons.business_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 14),
            _AlertBanner(
                color: AppColors.error,
                icon: Icons.error_outline_rounded,
                message: _errorMsg!),
          ],
          if (_showWakeUp) ...[
            const SizedBox(height: 8),
            const _AlertBanner(
              color: AppColors.warning,
              icon: Icons.hourglass_top_rounded,
              message:
                  'Servidor despertando… Esto solo ocurre en la primera conexión del día.',
              showSpinner: true,
            ),
          ],
          const SizedBox(height: 28),

          stagger(
            4,
            SizedBox(
              height: 54,
              child: PressScale(
                enabled: !_isLoading,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBtn,
                    foregroundColor: primaryBtnText,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (!_profileFormKey.currentState!.validate()) return;
                          FocusScope.of(context).unfocus();
                          if (_hasAcademicStep) {
                            ref.read(catalogProvider.notifier).loadCarreras();
                            _advanceStep(2);
                          } else {
                            _submitProfile();
                          }
                        },
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primaryBtnText),
                        )
                      : Text(
                          _hasAcademicStep ? 'Continuar' : 'Finalizar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryBtnText,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Step 2: Datos académicos ──────────────────────────────────────────
  Widget _buildStep2(
      bool isDark, Color accent, Widget Function(int, Widget) stagger) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final primaryBtn =
        isDark ? AppColors.darkPrimary : AppColors.lightForeground;
    final primaryBtnText =
        isDark ? AppColors.darkTextInverse : AppColors.lightCard;

    final catalog = ref.watch(catalogProvider);
    final carreras = catalog.carreras;
    final materias = catalog.materias;
    final loadingCatalogs = catalog.isLoading;
    final grupos = _gruposDeMateria(materias);

    final selectedCarreraLabel = carreras
        .cast<Map<String, dynamic>?>()
        .firstWhere((c) => c?['id'] == _selectedCarreraId,
            orElse: () => null)?['nombre'] as String?;

    String? selectedMateriaLabel;
    for (final entry in materias) {
      final m = entry['materia'] as Map<String, dynamic>?;
      if (m?['id'] == _selectedMateriaId) {
        selectedMateriaLabel =
            '${m?['nombre'] ?? ''} (${m?['cuatrimestre'] ?? ''}°)';
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // Selector carrera
        stagger(
          0,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormLabel('Carrera *', isDark: isDark),
              const SizedBox(height: 6),
              _SelectorRow(
                icon: Icons.school_rounded,
                placeholder: loadingCatalogs && carreras.isEmpty
                    ? 'Cargando...'
                    : 'Selecciona tu carrera',
                selectedLabel: selectedCarreraLabel,
                isDark: isDark,
                onTap: carreras.isEmpty
                    ? null
                    : () async {
                        final val = await _showSelectorSheet<String>(
                          ctx: context,
                          title: 'Selecciona carrera',
                          items: carreras,
                          selected: _selectedCarreraId,
                          labelOf: (c) => c['nombre'] as String? ?? '',
                          valueOf: (c) => c['id'] as String,
                        );
                        if (val != null) {
                          setState(() {
                            _selectedCarreraId = val;
                            _selectedMateriaId = null;
                            _selectedGruposIds = [];
                          });
                          ref.read(catalogProvider.notifier).selectCarrera(val);
                        }
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Selector materia (solo docentes)
        if (_isTeacher) ...[
          stagger(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormLabel('Materia *', isDark: isDark),
                const SizedBox(height: 6),
                _SelectorRow(
                  icon: Icons.book_outlined,
                  placeholder: _selectedCarreraId == null
                      ? 'Elige una carrera primero'
                      : loadingCatalogs
                          ? 'Cargando materias...'
                          : materias.isEmpty
                              ? 'Sin materias disponibles'
                              : 'Selecciona la materia que impartes',
                  selectedLabel: selectedMateriaLabel,
                  isDark: isDark,
                  onTap: _selectedCarreraId == null || materias.isEmpty
                      ? null
                      : () async {
                          final val = await _showSelectorSheet<String>(
                            ctx: context,
                            title: 'Selecciona materia',
                            items: materias,
                            selected: _selectedMateriaId,
                            labelOf: (e) {
                              final m = e['materia'] as Map<String, dynamic>?;
                              return m?['nombre'] as String? ?? '';
                            },
                            subtitleOf: (e) {
                              final m = e['materia'] as Map<String, dynamic>?;
                              final c = m?['cuatrimestre'];
                              return c != null ? '$c° cuatrimestre' : null;
                            },
                            valueOf: (e) {
                              final m = e['materia'] as Map<String, dynamic>?;
                              return m?['id'] as String;
                            },
                          );
                          if (val != null) {
                            setState(() {
                              _selectedMateriaId = val;
                              _selectedGruposIds = [];
                            });
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // FilterChips grupos
          if (_selectedMateriaId != null && grupos.isNotEmpty)
            stagger(
              2,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormLabel('Grupos', isDark: isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: grupos.map((g) {
                      final gId = g['id'] as String? ?? '';
                      final turno = g['turno'] as String? ?? '';
                      final nombre = g['nombre'] as String? ?? '';
                      final isSelected = _selectedGruposIds.contains(gId);
                      return FilterChip(
                        selected: isSelected,
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nombre,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? accent : textPrimary,
                              ),
                            ),
                            if (turno.isNotEmpty)
                              Text(
                                turno,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: isSelected
                                      ? accent.withOpacity(0.8)
                                      : mutedColor,
                                ),
                              ),
                          ],
                        ),
                        selectedColor: accent.withOpacity(0.15),
                        checkmarkColor: accent,
                        side: BorderSide(
                          color: isSelected
                              ? accent.withOpacity(0.4)
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        ),
                        backgroundColor: isDark
                            ? AppColors.darkSurface1
                            : AppColors.lightCard,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        onSelected: (checked) => setState(() {
                          if (checked) {
                            if (!_selectedGruposIds.contains(gId)) {
                              _selectedGruposIds.add(gId);
                            }
                          } else {
                            _selectedGruposIds.remove(gId);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],

        if (_errorMsg != null) ...[
          const SizedBox(height: 14),
          _AlertBanner(
              color: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: _errorMsg!),
        ],
        if (_showWakeUp) ...[
          const SizedBox(height: 8),
          const _AlertBanner(
            color: AppColors.warning,
            icon: Icons.hourglass_top_rounded,
            message:
                'Servidor despertando… Esto solo ocurre en la primera conexión del día.',
            showSpinner: true,
          ),
        ],
        const SizedBox(height: 28),

        stagger(
          4,
          SizedBox(
            height: 54,
            child: PressScale(
              enabled: !_isLoading && !loadingCatalogs,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBtn,
                  foregroundColor: primaryBtnText,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
                onPressed:
                    _isLoading || loadingCatalogs ? null : _submitProfile,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryBtnText),
                      )
                    : Text(
                        'Finalizar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryBtnText,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Step 3: Confirmación ──────────────────────────────────────────────
  Widget _buildStep3(
      bool isDark, Color accent, Widget Function(int, Widget) stagger) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final name =
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text.split(' ').first : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 64),
        stagger(
          0,
          Center(
            child: ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 42),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        stagger(
          1,
          Text(
            name.isNotEmpty ? '¡Listo, $name!' : '¡Cuenta creada!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        stagger(
          2,
          Text(
            'Tu cuenta ha sido configurada.\nYa puedes explorar la plataforma.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              height: 1.6,
              color: mutedColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        stagger(
          3,
          SizedBox(
            height: 54,
            child: PressScale(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.lightCard,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/showcase');
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ir a la plataforma',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  IconData _roleIcon(String role) => switch (role) {
        'Docente' => Icons.school_rounded,
        'Alumno' => Icons.menu_book_rounded,
        'SuperAdmin' => Icons.admin_panel_settings_rounded,
        _ => Icons.person_outline_rounded,
      };

  String _roleLabel(String role) => switch (role) {
        'Docente' => 'Docente UTM',
        'Alumno' => 'Alumno UTM',
        'SuperAdmin' => 'Admin',
        _ => 'Invitado',
      };
}

// ── Step Header con progress pills ─────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.totalSteps,
    required this.isDark,
    required this.accent,
    required this.onBack,
  });
  final int step;
  final int totalSteps;
  final bool isDark;
  final Color accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const titles = ['', 'Datos personales', 'Contexto académico', ''];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightForeground,
            ),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                titles[step.clamp(0, titles.length - 1)],
                key: ValueKey(step),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightForeground,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalSteps, (i) {
              final isActive = i + 1 == step;
              final isDone = i + 1 < step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                margin: const EdgeInsets.only(left: 4),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive || isDone ? accent : accent.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Selector Row ─────────────────────────────────────────────────────────────

class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.icon,
    required this.placeholder,
    required this.isDark,
    this.selectedLabel,
    this.onTap,
  });
  final IconData icon;
  final String placeholder;
  final String? selectedLabel;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkSurface1 : AppColors.lightCard;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled ? bg.withOpacity(0.5) : bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isDisabled ? mutedColor.withOpacity(0.4) : mutedColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedLabel ?? placeholder,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: selectedLabel != null
                      ? textPrimary
                      : mutedColor.withOpacity(isDisabled ? 0.4 : 1.0),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 18,
                color: isDisabled ? mutedColor.withOpacity(0.3) : mutedColor),
          ],
        ),
      ),
    );
  }
}

// ── Selector BottomSheet ──────────────────────────────────────────────────────

class _SelectorSheet<T> extends StatelessWidget {
  const _SelectorSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.valueOf,
    this.subtitleOf,
  });
  final String title;
  final List<Map<String, dynamic>> items;
  final T? selected;
  final String Function(Map<String, dynamic>) labelOf;
  final String? Function(Map<String, dynamic>)? subtitleOf;
  final T Function(Map<String, dynamic>) valueOf;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final surface = isDark ? AppColors.darkSurface1 : AppColors.lightCard;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightForeground;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightMutedFg;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: mutedColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final val = valueOf(item);
                    final isSelected = val == selected;
                    final subtitle = subtitleOf?.call(item);
                    return ListTile(
                      title: Text(
                        labelOf(item),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? accent : textPrimary,
                        ),
                      ),
                      subtitle: subtitle != null
                          ? Text(
                              subtitle,
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: mutedColor),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: accent, size: 18)
                          : null,
                      onTap: () => Navigator.of(context).pop(val),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
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
