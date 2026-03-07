// features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

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

      // 2. Llamar al backend con datos de Firebase
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {
          'firebaseUid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? cmd.email.split('@')[0],
          'photoUrl': user.photoURL,
        },
      );

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

  /// Verifica si hay sesión activa al iniciar la app
  Future<AuthAuthenticated?> getActiveSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      _logger.i('Verificando sesión activa para ${user.email}');

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
  Future<AuthAuthenticated> register(RegisterCommand cmd) async {
    User? firebaseUser;
    try {
      // 1. Crear cuenta en Firebase
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      firebaseUser = cred.user!;

      // 2. Registrar en la API backend
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
    } catch (e) {
      _logger.w('Rollback: no se pudo eliminar usuario Firebase', error: e);
    }
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
