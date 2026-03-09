// features/auth/data/datasources/auth_remote_datasource.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/commands/login_command.dart';
import '../../domain/models/auth_state.dart';

final _logger = Logger();

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;
  final _firebaseAuth = FirebaseAuth.instance;

  /// RF-01: Login — Firebase Auth + llamada directa al backend (sin JWT)
  Future<AuthAuthenticated> login(LoginCommand cmd) async {
    try {
      // 1. Firebase Auth
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      final user = cred.user!;

      // 2. Llamar al backend con reintentos (tolera Render cold-start ~15-45 s)
      final res = await _withRetry(() => _dio.post(
            ApiEndpoints.login,
            data: {
              'firebaseUid': user.uid,
              'email': user.email,
              'displayName': user.displayName ?? cmd.email.split('@')[0],
              'photoUrl': user.photoURL,
            },
          ));

      return _mapResponse(res.data as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      _logger.w('Firebase login error: ${e.code} — ${e.message}');
      throw ValidationException(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      _logger.e(
        'Backend login error [${e.response?.statusCode}]',
        error: e.response?.data ?? e.message,
      );
      throw handleDioError(e);
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// Verifica si hay sesión activa al iniciar la app.
  /// También limpia usuarios Firebase huérfanos pendientes.
  Future<AuthAuthenticated?> getActiveSession() async {
    // Limpiar huérfanos de intentos de registro anteriores fallidos
    await _cleanPendingRollbacks();
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      _logger.i('Verificando sesión activa para ${user.email}');

      final res = await _withRetry(() => _dio.post(
            ApiEndpoints.login,
            data: {
              'firebaseUid': user.uid,
              'email': user.email,
              'displayName':
                  user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
              'photoUrl': user.photoURL,
            },
          ));

      return _mapResponse(res.data as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      _logger.w('Firebase session check error: ${e.code}');
      return null;
    } on DioException catch (e) {
      _logger.w(
        'Backend no disponible al verificar sesión [${e.type}]',
        error: e.response?.data ?? e.message,
      );
      return null;
    } catch (e, st) {
      _logger.e('Error inesperado al verificar sesión',
          error: e, stackTrace: st);
      return null;
    }
  }

  /// RF-02: Registro de nuevo usuario - Firebase + API
  /// Si el backend falla, hace rollback eliminando el usuario de Firebase.
  Future<AuthAuthenticated> register(RegisterCommand cmd,
      {bool isRetry = false}) async {
    User? firebaseUser;
    try {
      // 1. Crear cuenta en Firebase
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      firebaseUser = cred.user!;

      // 2. Registrar en la API backend con reintentos
      final res = await _withRetry(() => _dio.post(
            ApiEndpoints.register,
            data: {
              'firebaseUid': firebaseUser!.uid,
              'email': cmd.email,
              'nombre': cmd.nombre,
              'apellidoPaterno': cmd.apellidoPaterno,
              'apellidoMaterno': cmd.apellidoMaterno,
              'rol': cmd.rol,
              'profesion': cmd.profesion,
              'organizacion': cmd.organizacion,
              'gruposDocente': cmd.gruposDocente,
              'carrerasIds': cmd.carrerasIds,
            },
          ));

      // 3. Verificar respuesta del backend (tolera PascalCase y camelCase)
      final data = res.data as Map<String, dynamic>;
      final success = (data['success'] ?? data['Success'] ?? false) as bool;
      if (!success) {
        throw ValidationException(
          (data['message'] ?? data['Message'] ?? 'Error en el registro')
              .toString(),
        );
      }

      // 4. Login automático tras registro exitoso
      return await login(
          LoginCommand(email: cmd.email, password: cmd.password));
    } on FirebaseAuthException catch (e) {
      _logger.w('Firebase register error: ${e.code}');
      // Cuenta ya existe en Firebase — puede ser un huérfano de intento previo
      if (e.code == 'email-already-in-use' && !isRetry) {
        try {
          // Intentamos login con las mismas credenciales
          final signIn = await _firebaseAuth.signInWithEmailAndPassword(
            email: cmd.email,
            password: cmd.password,
          );
          // Éxito → usuario huérfano confirmado → eliminarlo y reintentar
          _logger.i('Huérfano Firebase detectado (${cmd.email}), limpiando...');
          await _rollbackFirebaseUser(signIn.user);
          return await register(cmd, isRetry: true);
        } on FirebaseAuthException {
          // Contraseña diferente → conflicto real, no huérfano
        }
        throw const ValidationException(
          'Ya existe una cuenta con ese correo. '
          'Si olvidaste tu contraseña, recúpérala desde Iniciar sesión.',
        );
      }
      throw ValidationException(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      _logger.e(
        'Backend register error [${e.response?.statusCode}]',
        error: e.response?.data ?? e.message,
      );
      // Rollback: eliminar cuenta Firebase para no dejar usuario huérfano
      await _rollbackFirebaseUser(firebaseUser);
      throw handleDioError(e);
    } on AppException {
      // Rollback también si el backend retornó {success: false}
      await _rollbackFirebaseUser(firebaseUser);
      rethrow;
    }
  }

  /// Elimina el usuario de Firebase de forma segura (rollback ante error del backend)
  Future<void> _rollbackFirebaseUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
      _logger.i('Rollback: usuario Firebase eliminado (${user.email})');
      await _removePendingRollback(user.uid);
    } catch (e) {
      _logger.w('Rollback: no se pudo eliminar usuario Firebase, guardando para después', error: e);
      await _savePendingRollback(user.uid);
    }
  }

  // Clave para persistir UIDs de Firebase pendientes de eliminación
  static const _kPendingRollbackKey = 'pending_firebase_rollback_uids';

  Future<void> _savePendingRollback(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uids = prefs.getStringList(_kPendingRollbackKey) ?? [];
      if (!uids.contains(uid)) {
        uids.add(uid);
        await prefs.setStringList(_kPendingRollbackKey, uids);
      }
    } catch (_) {}
  }

  Future<void> _removePendingRollback(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uids = prefs.getStringList(_kPendingRollbackKey) ?? [];
      uids.remove(uid);
      await prefs.setStringList(_kPendingRollbackKey, uids);
    } catch (_) {}
  }

  /// Limpia usuarios Firebase huérfanos guardados en intentos previos.
  /// Solo puede eliminar al usuario actualmente autenticado.
  Future<void> _cleanPendingRollbacks() async {
    try {
      final current = _firebaseAuth.currentUser;
      if (current == null) return;
      final prefs = await SharedPreferences.getInstance();
      final uids = prefs.getStringList(_kPendingRollbackKey) ?? [];
      if (uids.contains(current.uid)) {
        _logger.i('Limpiando huérfano pendiente: ${current.uid}');
        await _rollbackFirebaseUser(current);
      }
    } catch (_) {}
  }

  /// Reintenta operaciones Dio hasta 3 veces con 5 s de espera entre intentos.
  /// Maneja el cold-start de Render (servidor dormido ~15-45 s).
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 5),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } on DioException catch (e) {
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout;
        if (isRetryable && attempt < maxAttempts) {
          _logger.i('Reintento $attempt/$maxAttempts tras ${e.type} — esperando ${delay.inSeconds}s...');
          await Future<void>.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
    throw const NetworkException();
  }

  /// Mapeo defensivo de la respuesta del backend.
  /// Tolera tanto camelCase (producción .NET) como PascalCase (cambios futuros).
  AuthAuthenticated _mapResponse(Map<String, dynamic> d) {
    String str(String a, String b) => ((d[a] ?? d[b]) ?? '').toString();
    String? strN(String a, String b) => (d[a] ?? d[b]) as String?;
    bool flag(String a, String b) => (d[a] ?? d[b] ?? false) as bool;

    return AuthAuthenticated(
      uid: str('userId', 'UserId'),
      email: str('email', 'Email'),
      displayName: str('nombre', 'Nombre'),
      role: str('rol', 'Rol'),
      photoUrl: strN('fotoUrl', 'FotoUrl'),
      isFirstLogin: flag('isFirstLogin', 'IsFirstLogin'),
      grupoId: strN('grupoId', 'GrupoId'),
      grupoNombre: strN('grupoNombre', 'GrupoNombre'),
      matricula: strN('matricula', 'Matricula'),
      carreraId: strN('carreraId', 'CarreraId'),
      apellidoPaterno: strN('apellidoPaterno', 'ApellidoPaterno'),
      apellidoMaterno: strN('apellidoMaterno', 'ApellidoMaterno'),
      profesion: strN('profesion', 'Profesion'),
      organizacion: strN('organizacion', 'Organizacion'),
      especialidadDocente: strN('especialidadDocente', 'EspecialidadDocente'),
      createdAt: strN('createdAt', 'CreatedAt'),
    );
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'wrong-password' => 'Contraseña incorrecta.',
        'invalid-credential' => 'Correo o contraseña incorrectos.',
        'invalid-email' => 'Correo inválido.',
        'user-disabled' => 'Cuenta deshabilitada.',
        'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres).',
        _ => 'Error de autenticación.',
      };
}
