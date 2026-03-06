// features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/commands/login_command.dart';
import '../../domain/models/auth_state.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._dio);

  final Dio _dio;
  final _firebaseAuth = FirebaseAuth.instance;

  /// RF-01: Login — Firebase Auth + obtiene perfil de la API
  Future<AuthAuthenticated> login(LoginCommand cmd) async {
    try {
      // 1. Firebase Auth
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      final user = cred.user!;
      final idToken = await user.getIdToken();

      // 2. Intercambiar Firebase token por JWT de la API
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'firebaseToken': idToken},
      );

      final data = res.data as Map<String, dynamic>;
      await persistTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );

      // 3. Obtener perfil del usuario desde la API
      final profileRes = await _dio.get(ApiEndpoints.profile);
      final profile = profileRes.data as Map<String, dynamic>;

      return AuthAuthenticated(
        uid: user.uid,
        email: user.email ?? cmd.email,
        displayName:
            profile['displayName'] as String? ?? user.displayName ?? '',
        role: profile['role'] as String? ?? 'visitor',
        photoUrl: profile['photoUrl'] as String?,
      );
    } on FirebaseAuthException catch (e) {
      throw ValidationException(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Cierra sesion
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await clearTokens();
  }

  /// Verifica si hay sesion activa al iniciar la app
  Future<AuthAuthenticated?> getActiveSession() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final token = await getAccessToken();
      if (token == null) return null;

      final profileRes = await _dio.get(ApiEndpoints.profile);
      final profile = profileRes.data as Map<String, dynamic>;

      return AuthAuthenticated(
        uid: user.uid,
        email: user.email ?? '',
        displayName: profile['displayName'] as String? ?? '',
        role: profile['role'] as String? ?? 'visitor',
        photoUrl: profile['photoUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// RF-02: Registro de nuevo usuario - Firebase + API
  Future<AuthAuthenticated> register(RegisterCommand cmd) async {
    try {
      // 1. Crear cuenta en Firebase
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cmd.email,
        password: cmd.password,
      );
      final user = cred.user!;

      // 2. Registrar en la API backend con todos los campos
      final registerData = {
        'firebaseUid': user.uid,
        'email': cmd.email,
        'nombre': cmd.nombre,
        if (cmd.apellidoPaterno != null) 'apellidoPaterno': cmd.apellidoPaterno,
        if (cmd.apellidoMaterno != null) 'apellidoMaterno': cmd.apellidoMaterno,
        'rol': cmd.rol,
        if (cmd.profesion != null) 'profesion': cmd.profesion,
        if (cmd.organizacion != null) 'organizacion': cmd.organizacion,
        if (cmd.carrerasIds.isNotEmpty) 'carrerasIds': cmd.carrerasIds,
        if (cmd.gruposDocente.isNotEmpty) 'gruposDocente': cmd.gruposDocente,
      };

      final res = await _dio.post(
        ApiEndpoints.register,
        data: registerData,
      );

      // 3. La API puede retornar tokens directamente o requerir login
      final data = res.data as Map<String, dynamic>;
      if (data.containsKey('accessToken')) {
        await persistTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );

        // Obtener perfil
        final profileRes = await _dio.get(ApiEndpoints.profile);
        final profile = profileRes.data as Map<String, dynamic>;

        return AuthAuthenticated(
          uid: user.uid,
          email: user.email ?? cmd.email,
          displayName: profile['displayName'] as String? ?? cmd.nombre,
          role: profile['role'] as String? ?? cmd.rol.toLowerCase(),
          photoUrl: profile['photoUrl'] as String?,
        );
      } else {
        // API solo confirma registro, hacer login separado
        return await login(
            LoginCommand(email: cmd.email, password: cmd.password));
      }
    } on FirebaseAuthException catch (e) {
      throw ValidationException(_mapFirebaseError(e.code));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
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
