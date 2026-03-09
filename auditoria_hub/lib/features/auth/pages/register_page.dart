// features/auth/pages/register_page.dart — Pantalla de registro (diseño profesional)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/form_label.dart';
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

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _showWakeUp = false;
  Timer? _wakeUpTimer;
  String? _errorMsg;

  // ── Step 2 — Asignación docente ─────────────────────────────────────────
  int _registerStep = 1;
  List<Map<String, dynamic>> _carreras = [];
  List<Map<String, dynamic>> _availableMaterias = [];
  String? _selectedCarreraId;
  String? _selectedMateriaId;
  List<String> _selectedGruposIds = [];
  bool _loadingCatalogs = false;

  // Cache de detección de rol para evitar lookups excesivos
  String _cachedDetectedRole = 'Invitado';
  String _lastEmailChecked = '';

  String get _detectedRole {
    if (_emailCtrl.text != _lastEmailChecked) {
      _lastEmailChecked = _emailCtrl.text;
      _cachedDetectedRole = RoleDetector.fromEmail(_emailCtrl.text);
    }
    return _cachedDetectedRole;
  }

  bool get _isGuest => _detectedRole == 'Invitado';
  bool get _isTeacher => _detectedRole == 'Docente';

  @override
  void initState() {
    super.initState();
    // Optimizar listener con debounce para evitar rebuilds excesivos
    _emailCtrl.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    // Solo actualizar UI si el rol realmente cambió
    final newRole = RoleDetector.fromEmail(_emailCtrl.text);
    if (newRole != _cachedDetectedRole) {
      setState(() {
        _cachedDetectedRole = newRole;
        _lastEmailChecked = _emailCtrl.text;
      });
    }
  }

  Future<void> _loadCarreras() async {
    setState(() => _loadingCatalogs = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.adminCarreras);
      final list = (response.data as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _carreras = list);
    } catch (_) {
      // fallback silencioso
    } finally {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  Future<void> _onCarreraChanged(String? carreraId) async {
    setState(() {
      _selectedCarreraId = carreraId;
      _selectedMateriaId = null;
      _selectedGruposIds = [];
      _availableMaterias = [];
      _loadingCatalogs = carreraId != null;
    });
    if (carreraId == null) return;
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '${ApiEndpoints.adminMaterias}/available',
        queryParameters: {'carreraId': carreraId},
      );
      final list = (response.data as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _availableMaterias = list);
    } catch (_) {
      // fallback silencioso
    } finally {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  List<Map<String, dynamic>> get _gruposDeMateria {
    if (_selectedMateriaId == null) return [];
    for (final entry in _availableMaterias) {
      final mat = entry['materia'] as Map<String, dynamic>?;
      if (mat?['id'] == _selectedMateriaId) {
        return (entry['gruposDisponibles'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_onEmailChanged);
    _wakeUpTimer?.cancel();
    _nameCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    // ── Step 2: sin validación obligatoria — datos pueden ser nulos ──────────
    if (_isTeacher && _registerStep == 2) {
      setState(() => _errorMsg = null);
    } else {
      // ── Step 1: validación del formulario ────────────────────────────────
      if (!_formKey.currentState!.validate()) return;

      // Docente: avanzar al Step 2 para asignación de grupos
      if (_isTeacher) {
        FocusScope.of(context).unfocus();
        await _loadCarreras();
        setState(() {
          _registerStep = 2;
          _errorMsg = null;
        });
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _showWakeUp = false;
    });
    // Mostrar aviso de wake-up si el servidor tarda más de 8 s
    _wakeUpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLoading) setState(() => _showWakeUp = true);
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
        profesion: null,
        organizacion: _isGuest && _orgCtrl.text.trim().isNotEmpty
            ? _orgCtrl.text.trim()
            : null,
        carrerasIds: _isTeacher && _selectedCarreraId != null
            ? [_selectedCarreraId!]
            : const [],
        gruposDocente: _isTeacher && _selectedGruposIds.isNotEmpty
            ? _selectedGruposIds
            : const [],
      );

      await ref.read(authStateProvider.notifier).register(cmd);

      if (!mounted) return;
      _wakeUpTimer?.cancel();
      setState(() {
        _isLoading = false;
        _showWakeUp = false;
      });

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
      _wakeUpTimer?.cancel();
      setState(() {
        _isLoading = false;
        _showWakeUp = false;
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
                        onTap: () {
                          if (_isTeacher && _registerStep == 2) {
                            setState(() {
                              _registerStep = 1;
                              _errorMsg = null;
                            });
                          } else {
                            context.go('/login');
                          }
                        },
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
                          Text(
                            _isTeacher && _registerStep == 2
                                ? 'Asignación docente'
                                : 'Crear cuenta',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isTeacher && _emailCtrl.text.isNotEmpty
                                ? 'Paso $_registerStep de 2 · UTM'
                                : 'Evaluacion de proyectos · UTM',
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenH - (screenH * 0.28),
                ),
                child: Container(
                  color: isDark ? AppColors.darkSurface1 : Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── STEP 1: Datos personales ─────────────────────────────────
                        if (_registerStep == 1) ...[
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
                          const SizedBox(height: 12),

                          // ── Apellidos — dos columnas ─────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _FieldLabel('Ap. Paterno', isDark: isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _apellidoPaternoCtrl,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        hintText: 'Paterno',
                                        prefixIcon: Icon(
                                            Icons.person_2_outlined,
                                            size: 16),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _FieldLabel('Ap. Materno', isDark: isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _apellidoMaternoCtrl,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        hintText: 'Materno',
                                        prefixIcon: Icon(
                                            Icons.person_3_outlined,
                                            size: 16),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Correo ──────────────────────────────────────────
                          _FieldLabel('Correo electrónico *', isDark: isDark),
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

                          // ── Role badge — aparece al detectar rol ─────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                            child: _emailCtrl.text.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _RoleBadge(
                                      role: _detectedRole,
                                      isDark: isDark,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // ── Contraseña ───────────────────────────────────────
                          _FieldLabel('Contraseña *', isDark: isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Mínimo 6 caracteres',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa una contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ── Confirmar contraseña ─────────────────────────────
                          _FieldLabel('Confirmar contraseña *', isDark: isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: 'Repite tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 18),
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
                            onFieldSubmitted: (_) => _submitRegister(),
                          ),

                          // ── Organización — solo invitados ─────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            child: _emailCtrl.text.isNotEmpty && _isGuest
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _FieldLabel('Organización',
                                            isDark: isDark),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _orgCtrl,
                                          textInputAction: TextInputAction.done,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Institución u organización (opcional)',
                                            prefixIcon: Icon(
                                                Icons.business_outlined,
                                                size: 18),
                                          ),
                                          onFieldSubmitted: (_) =>
                                              _submitRegister(),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ], // end step 1

                        // ── STEP 2: Asignación docente ─────────────────────────────────
                        if (_isTeacher && _registerStep == 2) ...[
                          // ── Carrera ───────────────────────────────────────
                          _FieldLabel('Carrera *', isDark: isDark),
                          const SizedBox(height: 6),
                          if (_loadingCatalogs && _carreras.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedCarreraId,
                              hint: Text(
                                _carreras.isEmpty
                                    ? 'No hay datos disponibles'
                                    : 'Selecciona tu carrera',
                              ),
                              decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.school_rounded, size: 18),
                              ),
                              items: _carreras
                                  .map((c) => DropdownMenuItem<String>(
                                        value: c['id'] as String?,
                                        child:
                                            Text(c['nombre'] as String? ?? ''),
                                      ))
                                  .toList(),
                              onChanged:
                                  _carreras.isEmpty ? null : _onCarreraChanged,
                            ),
                          const SizedBox(height: 12),

                          // ── Materia ───────────────────────────────────────
                          _FieldLabel('Materia *', isDark: isDark),
                          const SizedBox(height: 6),
                          if (_loadingCatalogs && _selectedCarreraId != null)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: _selectedMateriaId,
                              hint: Text(
                                _selectedCarreraId == null
                                    ? 'Elige una carrera primero'
                                    : _availableMaterias.isEmpty
                                        ? 'No hay datos disponibles'
                                        : 'Selecciona la materia que impartes',
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.book_outlined, size: 18),
                              ),
                              items: _availableMaterias.map((entry) {
                                final m =
                                    entry['materia'] as Map<String, dynamic>? ??
                                        {};
                                return DropdownMenuItem<String>(
                                  value: m['id'] as String?,
                                  child: Text(
                                    '${m['nombre'] ?? ''} '
                                    '(${m['cuatrimestre'] ?? ''}°)',
                                  ),
                                );
                              }).toList(),
                              onChanged: _selectedCarreraId == null ||
                                      _availableMaterias.isEmpty
                                  ? null
                                  : (val) => setState(() {
                                        _selectedMateriaId = val;
                                        _selectedGruposIds = [];
                                      }),
                            ),
                          const SizedBox(height: 12),

                          // ── Grupos ─────────────────────────────────────────
                          if (_selectedMateriaId != null &&
                              _gruposDeMateria.isNotEmpty) ...[
                            _FieldLabel('Grupos *', isDark: isDark),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface0
                                    : AppColors.lightBackground,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: _gruposDeMateria.map((g) {
                                  final gId = g['id'] as String? ?? '';
                                  final turno = g['turno'] as String? ?? '';
                                  return CheckboxListTile(
                                    value: _selectedGruposIds.contains(gId),
                                    title: Text(
                                      '${g["nombre"] ?? ""}'
                                      '${turno.isNotEmpty ? "  ·  $turno" : ""}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                      ),
                                    ),
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (checked) => setState(() {
                                      if (checked == true) {
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
                            ),
                            const SizedBox(height: 12),
                          ],
                        ], // end step 2

                        // ── Error ────────────────────────────────────────
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 14),
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

                        if (_showWakeUp) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: Colors.orange.withAlpha(80)),
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

                        const SizedBox(height: 24),
                        BioButton(
                          label: _isTeacher && _registerStep == 1
                              ? 'Continuar →'
                              : 'Crear cuenta',
                          isLoading: _isLoading || _loadingCatalogs,
                          onPressed: _submitRegister,
                        ),
                        if (_registerStep == 1) ...[
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child:
                                const Text('¿Ya tienes cuenta? Inicia sesión'),
                          ),
                        ],
                      ],
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
}

// ── Subwidgets ──────────────────────────────────────────────────────────────
// Alias local para mantener compat con el widget tree existente
typedef _FieldLabel = FormLabel;

// ── Role badge — tarjeta de rol detectado ─────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isDark});
  final String role;
  final bool isDark;

  IconData get _icon => switch (role) {
        'Docente' => Icons.school_rounded,
        'Alumno' => Icons.person_rounded,
        'SuperAdmin' => Icons.admin_panel_settings_rounded,
        _ => Icons.business_center_rounded,
      };

  String get _description => switch (role) {
        'Docente' => 'Correo docente UTM — acceso al panel de enseñanza',
        'Alumno' => 'Correo alumno UTM — acceso a proyectos y evaluaciones',
        'SuperAdmin' => 'Cuenta de administrador — acceso total al sistema',
        _ => 'Correo externo — acceso como invitado',
      };

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(role),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(18) : color.withAlpha(12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra lateral de acento
              Container(width: 4, color: color),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(_icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        role,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _description,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightMutedFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
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
