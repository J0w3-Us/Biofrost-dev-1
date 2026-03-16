import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/commands/login_command.dart';
import '../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';

class CompleteProfileController {
  const CompleteProfileController(this.ref);

  final WidgetRef ref;

  Future<AuthState> completeProfile({
    required String firebaseUid,
    required String nombre,
    required String? apellidoPaterno,
    required String? apellidoMaterno,
    required String email,
    required String rol,
    required String? organizacion,
    required List<DocenteAsignacion> asignaciones,
  }) async {
    final notifier = ref.read(authStateProvider.notifier);

    await notifier.completeProfile(
      CompleteProfileCommand(
        firebaseUid: firebaseUid,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        email: email,
        rol: rol,
        profesion: null,
        organizacion: organizacion,
        asignaciones: asignaciones,
      ),
    );

    return ref.read(authStateProvider);
  }
}
