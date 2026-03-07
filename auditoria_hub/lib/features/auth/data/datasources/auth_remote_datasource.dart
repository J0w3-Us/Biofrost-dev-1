// features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/commands/login_command.dart';
import '../../domain/models/auth_state.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;
  final _firebaseAuth = FirebaseAuth.instance;
  final _logger = Logger();

  /// RF-01: Login — Firebase Auth + llamada directa al backend (sin JWT)
  /// Mismo flujo que el frontend web: Firebase → POST /api/auth/login con UID
  Future<AuthAuthenticated> login(LoginCommand cmd) async {
    try {
      // 1. Firebase Auth
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      final user = cred.user!;
      _logger.i('Firebase Auth OK: ${user.uid}');

      // 2. Backend: registrar/sincronizar sesión usando Firebase UID
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {
          'firebaseUid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? cmd.email.split('@')[0],
          'photoUrl': user.photoURL,
        },
      );

      _logger.i('Backend login OK: status ${res.statusCode}');
      return _parseLoginResponse(res.data as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      _logger.w('FirebaseAuth error: ${e.code}');
      throw ValidationException(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      _logger.e(
        'Backend login error: ${e.type} — ${e.response?.statusCode}',
        error: e.response?.data,
      );
      throw mapDioError(e);
    }
  }

  /// Cierra sesion
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _logger.i('Sesión cerrada');
  }

  /// Verifica si hay sesion activa al iniciar la app
  Future<AuthAuthenticated?> getActiveSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _logger.i('getActiveSession: sin sesión Firebase activa');
        return null;
      }
      _logger.i('getActiveSession: sesión encontrada para ${user.email}');

      final res = await _dio.post(
        ApiEndpoints.login,
        data: {
          'firebaseUid': user.uid,
          'email': user.email,
          'displayName':
              user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
          'photoUrl': user.photoURL,
        },
      );

      _logger.i('getActiveSession: backend respondió ${res.statusCode}');
      return _parseLoginResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.w(
        'getActiveSession: error de red [${e.type}] — ${e.response?.statusCode}',
        error: e.message,
      );
      return null;
    } catch (e) {
      _logger.e('getActiveSession: error inesperado', error: e);
      return null;
    }
  }

  /// RF-02: Registro de nuevo usuario - Firebase + API
  Future<AuthAuthenticated> register(RegisterCommand cmd) async {
    // user se guarda para poder hacer rollback si el backend falla
    User? firebaseUser;
    try {
      // 1. Crear cuenta en Firebase
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      firebaseUser = cred.user!;
      _logger.i('Firebase register OK: ${firebaseUser.uid}');

      // 2. Registrar en el backend con la misma estructura que el frontend web
      final res = await _dio.post(
        ApiEndpoints.register,
        data: {
          'firebaseUid': firebaseUser.uid,
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
      );

      // 3. Verificar éxito del backend
      final data = res.data as Map<String, dynamic>;
      final success =
          data['success'] as bool? ?? data['Success'] as bool? ?? false;
      if (!success) {
        final msg =
            (data['message'] ?? data['Message'] ?? 'Error en el registro')
                .toString();
        throw ValidationException(msg);
      }
      _logger.i('Backend register OK para ${cmd.email}');

      // 4. Login automático usando los datos recién registrados
      return await login(
          LoginCommand(email: cmd.email, password: cmd.password));
    } on FirebaseAuthException catch (e) {
      _logger.w('FirebaseAuth register error: ${e.code}');
      throw ValidationException(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      // ROLLBACK: si el backend falló, eliminar el usuario de Firebase
      // para que no quede un usuario huérfano sin perfil en Firestore
      if (firebaseUser != null) {
        _logger.w(
            'Backend falló — eliminando usuario Firebase ${firebaseUser.uid} para rollback');
        await firebaseUser.delete().catchError(
              (err) => _logger.e('Rollback Firebase failed', error: err),
            );
      }
      _logger.e(
        'Backend register error: ${e.type} — ${e.response?.statusCode}',
        error: e.response?.data,
      );
      throw mapDioError(e);
    }
  }

  /// Mapea la respuesta del backend al modelo AuthAuthenticated
  /// Soporta camelCase y PascalCase para tolerar cambios del serializador .NET
  AuthAuthenticated _parseLoginResponse(Map<String, dynamic> d) {
    String pick(String lower, String upper) =>
        (d[lower] ?? d[upper] ?? '') as String;
    String? pickNull(String lower, String upper) =>
        (d[lower] ?? d[upper]) as String?;
    bool pickBool(String lower, String upper) =>
        (d[lower] ?? d[upper] ?? false) as bool;

    return AuthAuthenticated(
      uid: pick('userId', 'UserId'),
      email: pick('email', 'Email'),
      displayName: pick('nombre', 'Nombre'),
      role: pick('rol', 'Rol'),
      photoUrl: pickNull('fotoUrl', 'FotoUrl'),
      isFirstLogin: pickBool('isFirstLogin', 'IsFirstLogin'),
      grupoId: pickNull('grupoId', 'GrupoId'),
      grupoNombre: pickNull('grupoNombre', 'GrupoNombre'),
      matricula: pickNull('matricula', 'Matricula'),
      carreraId: pickNull('carreraId', 'CarreraId'),
      apellidoPaterno: pickNull('apellidoPaterno', 'ApellidoPaterno'),
      apellidoMaterno: pickNull('apellidoMaterno', 'ApellidoMaterno'),
      profesion: pickNull('profesion', 'Profesion'),
      organizacion: pickNull('organizacion', 'Organizacion'),
      especialidadDocente:
          pickNull('especialidadDocente', 'EspecialidadDocente'),
      createdAt: pickNull('createdAt', 'CreatedAt'),
    );
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'wrong-password' => 'Contraseña incorrecta.',
        'invalid-email' => 'Correo inválido.',
        'user-disabled' => 'Cuenta deshabilitada.',
        'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'weak-password' => 'La contraseña es muy débil.',
        _ => 'Error de autenticación.',
      };
}
