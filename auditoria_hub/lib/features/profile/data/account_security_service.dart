import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/api_service.dart';

final accountSecurityServiceProvider = Provider<AccountSecurityService>(
  (ref) => AccountSecurityService(
    dio: ref.watch(dioProvider),
    firebaseAuth: FirebaseAuth.instance,
  ),
);

class AccountSecurityService {
  AccountSecurityService({
    required Dio dio,
    required FirebaseAuth firebaseAuth,
  })  : _dio = dio,
        _firebaseAuth = firebaseAuth;

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _reauthenticate(currentPassword);
    final user = _requireUser();
    await user.updatePassword(newPassword);
  }

  Future<void> softDeleteAccount({required String currentPassword}) async {
    await _reauthenticate(currentPassword);
    final user = _requireUser();

    try {
      await _dio.put(
        ApiEndpoints.userSoftDelete(user.uid),
        data: {
          'currentPassword': currentPassword,
          'provider': 'firebase',
          'action': 'soft_delete',
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> _reauthenticate(String currentPassword) async {
    final user = _requireUser();
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const ValidationException(
        'No se pudo validar tu sesión. Inicia sesión de nuevo.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const ValidationException('La contraseña actual es incorrecta.');
      }
      throw ValidationException(
        'No se pudo validar tu identidad: ${e.message ?? e.code}',
      );
    }
  }

  User _requireUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const UnauthorizedException(
          'Tu sesión expiró. Vuelve a iniciar sesión.');
    }
    return user;
  }
}
