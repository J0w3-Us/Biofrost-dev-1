import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/account_security_service.dart';

class AccountSettingsState {
  const AccountSettingsState({
    this.isLoading = false,
    this.biometricEnabled = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool biometricEnabled;
  final String? errorMessage;
  final String? successMessage;

  AccountSettingsState copyWith({
    bool? isLoading,
    bool? biometricEnabled,
    String? errorMessage,
    String? successMessage,
  }) {
    return AccountSettingsState(
      isLoading: isLoading ?? this.isLoading,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final accountSettingsControllerProvider =
    NotifierProvider<AccountSettingsController, AccountSettingsState>(
  AccountSettingsController.new,
);

class AccountSettingsController extends Notifier<AccountSettingsState> {
  @override
  AccountSettingsState build() => const AccountSettingsState();

  AccountSecurityService get _security =>
      ref.read(accountSecurityServiceProvider);

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  String? validateNewPassword(String value) {
    final password = value.trim();
    if (password.length < 10) {
      return 'La nueva contraseña debe tener al menos 10 caracteres.';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    if (!hasUpper || !hasLower || !hasNumber || !hasSpecial) {
      return 'Incluye mayúscula, minúscula, número y carácter especial.';
    }
    return null;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Debes ingresar tu contraseña actual.',
        successMessage: null,
      );
      return false;
    }

    final passwordValidation = validateNewPassword(newPassword);
    if (passwordValidation != null) {
      state = state.copyWith(
        errorMessage: passwordValidation,
        successMessage: null,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _security.changePassword(
        currentPassword: currentPassword.trim(),
        newPassword: newPassword.trim(),
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Contraseña actualizada correctamente.',
        errorMessage: null,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        successMessage: null,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo actualizar la contraseña.',
        successMessage: null,
      );
      return false;
    }
  }

  Future<void> toggleBiometric(bool enable) async {
    if (!enable) {
      state = state.copyWith(
        biometricEnabled: false,
        errorMessage: null,
        successMessage: 'Biometría desactivada.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final approved = await _security.authenticateBiometricActivation();
      if (!approved) {
        state = state.copyWith(
          isLoading: false,
          biometricEnabled: false,
          errorMessage: 'No se pudo verificar tu identidad biométrica.',
          successMessage: null,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        biometricEnabled: true,
        errorMessage: null,
        successMessage: 'Biometría activada correctamente.',
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        biometricEnabled: false,
        errorMessage: e.message,
        successMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        biometricEnabled: false,
        errorMessage: 'No se pudo activar la biometría.',
        successMessage: null,
      );
    }
  }

  Future<bool> deleteAccountWithVerification({
    required String currentPassword,
  }) async {
    if (currentPassword.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Debes ingresar tu contraseña para continuar.',
        successMessage: null,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _security.softDeleteAccount(
          currentPassword: currentPassword.trim());
      await ref.read(authStateProvider.notifier).logout();

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        successMessage: 'Tu cuenta fue marcada para eliminación.',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        successMessage: null,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo eliminar la cuenta.',
        successMessage: null,
      );
      return false;
    }
  }
}
