// features/auth/providers/auth_provider.dart — Riverpod Notifier (CQRS)
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
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
  }

  /// RF-01: Login con email + password
  Future<void> login(LoginCommand cmd) async {
    state = const AuthLoading();
    try {
      final authState = await _datasource.login(cmd);
      state = authState;
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
    } catch (e) {
      state = AuthError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// Cerrar sesion
  Future<void> logout() async {
    await _datasource.logout();
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
