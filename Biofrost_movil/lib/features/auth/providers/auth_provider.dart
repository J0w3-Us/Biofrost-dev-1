// features/auth/providers/auth_provider.dart — Riverpod Notifier (CQRS)
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_database.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_bootstrap_service.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../domain/commands/login_command.dart';
import '../domain/models/auth_state.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(ref.watch(dioProvider)),
);

/// Provider del estado global de autenticacion
final authStateProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> implements ChangeNotifier {
  // Listeners para GoRouter refresh
  final List<VoidCallback> _listeners = [];

  @override
  AuthState build() {
    _checkSession();
    return const AuthLoading();
  }

  AuthRemoteDatasource get _datasource =>
      ref.read(authRemoteDatasourceProvider);

  /// Verifica sesion al arrancar la app
  Future<void> _checkSession() async {
    final session = await _datasource.getActiveSession();
    state = session ?? const AuthUnauthenticated();
    notifyListeners();
    // Pre-cargar caché en background si la sesión está activa
    if (session != null) {
      ref.read(appBootstrapServiceProvider).run();
    }
  }

  /// RF-01: Login con email + password
  Future<void> login(LoginCommand cmd) async {
    state = const AuthLoading();
    try {
      final authState = await _datasource.login(cmd);
      state = authState;
      // Pre-cargar caché en background tras login exitoso
      ref.read(appBootstrapServiceProvider).run();
    } catch (e) {
      state = AuthError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// RF-01b: Crear cuenta nueva en Firebase, luego llama al backend para detectar isFirstLogin
  Future<void> createAccount(LoginCommand cmd) async {
    state = const AuthLoading();
    try {
      final authState = await _datasource.createAccount(cmd);
      state = authState;
      ref.read(appBootstrapServiceProvider).run();
    } catch (e) {
      state = AuthError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// RF-02: Registro de nuevo usuario
  Future<void> register(RegisterCommand cmd) async {
    state = const AuthLoading();
    try {
      final authState = await _datasource.register(cmd);
      state = authState;
      ref.read(appBootstrapServiceProvider).run();
    } catch (e) {
      state = AuthError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// RF-03: Completar perfil post-login
  Future<void> completeProfile(CompleteProfileCommand cmd) async {
    state = const AuthLoading();
    try {
      final authState = await _datasource.completeProfile(cmd);
      state = authState;
    } catch (e) {
      state = AuthError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// Actualiza el photoUrl en el estado local tras una subida exitosa.
  void updatePhotoInState(String photoUrl) {
    final current = state;
    if (current is! AuthAuthenticated) return;
    state = AuthAuthenticated(
      uid: current.uid,
      email: current.email,
      displayName: current.displayName,
      role: current.role,
      photoUrl: photoUrl,
      isFirstLogin: current.isFirstLogin,
      grupoId: current.grupoId,
      grupoNombre: current.grupoNombre,
      matricula: current.matricula,
      carreraId: current.carreraId,
      apellidoPaterno: current.apellidoPaterno,
      apellidoMaterno: current.apellidoMaterno,
      profesion: current.profesion,
      organizacion: current.organizacion,
      especialidadDocente: current.especialidadDocente,
      createdAt: current.createdAt,
      socialLinks: current.socialLinks,
    );
    notifyListeners();
  }

  /// Actualiza redes sociales en el estado local tras guardado exitoso.
  void updateSocialLinksInState(Map<String, String> links) {
    final current = state;
    if (current is! AuthAuthenticated) return;
    state = AuthAuthenticated(
      uid: current.uid,
      email: current.email,
      displayName: current.displayName,
      role: current.role,
      photoUrl: current.photoUrl,
      isFirstLogin: current.isFirstLogin,
      grupoId: current.grupoId,
      grupoNombre: current.grupoNombre,
      matricula: current.matricula,
      carreraId: current.carreraId,
      apellidoPaterno: current.apellidoPaterno,
      apellidoMaterno: current.apellidoMaterno,
      profesion: current.profesion,
      organizacion: current.organizacion,
      especialidadDocente: current.especialidadDocente,
      createdAt: current.createdAt,
      socialLinks: links,
    );
    notifyListeners();
  }

  /// Actualiza el nombre de display en el estado local tras guardado exitoso.
  void updateDisplayNameInState(String name) {
    final current = state;
    if (current is! AuthAuthenticated) return;
    state = AuthAuthenticated(
      uid: current.uid,
      email: current.email,
      displayName: name,
      role: current.role,
      photoUrl: current.photoUrl,
      isFirstLogin: current.isFirstLogin,
      grupoId: current.grupoId,
      grupoNombre: current.grupoNombre,
      matricula: current.matricula,
      carreraId: current.carreraId,
      apellidoPaterno: current.apellidoPaterno,
      apellidoMaterno: current.apellidoMaterno,
      profesion: current.profesion,
      organizacion: current.organizacion,
      especialidadDocente: current.especialidadDocente,
      createdAt: current.createdAt,
      socialLinks: current.socialLinks,
    );
    notifyListeners();
  }


  /// Cerrar sesion — limpia la BD local para no dejar datos del usuario anterior.
  Future<void> logout() async {
    await _datasource.logout();
    // Limpiar caché local para que el próximo usuario vea datos frescos
    await CacheDatabase.instance.clearAll();
    state = const AuthUnauthenticated();
    notifyListeners();
  }

  // ChangeNotifier impl para GoRouter
  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  void dispose() => _listeners.clear();
}

// ── Catálogos (carreras / materias para registro docente) ─────────────────

class CatalogState {
  const CatalogState({
    this.carreras = const [],
    this.materias = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Map<String, dynamic>> carreras;
  final List<Map<String, dynamic>> materias;
  final bool isLoading;
  final String? error;

  CatalogState copyWith({
    List<Map<String, dynamic>>? carreras,
    List<Map<String, dynamic>>? materias,
    bool? isLoading,
    String? error,
  }) =>
      CatalogState(
        carreras: carreras ?? this.carreras,
        materias: materias ?? this.materias,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final catalogProvider =
    NotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);

class CatalogNotifier extends Notifier<CatalogState> {
  @override
  CatalogState build() => const CatalogState();

  AuthRemoteDatasource get _datasource =>
      ref.read(authRemoteDatasourceProvider);

  Future<void> loadCarreras() async {
    if (state.carreras.isNotEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _datasource.loadCarreras();
      state = state.copyWith(carreras: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> selectCarrera(String carreraId) async {
    state = state.copyWith(materias: [], isLoading: true, error: null);
    try {
      final list = await _datasource.loadMaterias(carreraId);
      state = state.copyWith(materias: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const CatalogState();
}
