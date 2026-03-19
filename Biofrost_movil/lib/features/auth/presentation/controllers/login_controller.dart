import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/commands/login_command.dart';
import '../../domain/models/auth_state.dart';
import '../../providers/auth_provider.dart';

class LoginController {
  const LoginController(this.ref);

  final WidgetRef ref;

  String detectRoleFromEmail(String email) {
    return RoleDetector.fromEmail(email);
  }

  Future<AuthState> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final notifier = ref.read(authStateProvider.notifier);
    await notifier.login(
      LoginCommand(
        email: email.trim(),
        password: password,
      ),
    );
    return ref.read(authStateProvider);
  }

  Future<AuthState> loginWithGoogle({
    required GoogleSignIn googleSignIn,
    required FirebaseAuth firebaseAuth,
  }) async {
    final notifier = ref.read(authStateProvider.notifier);

    // Force account picker so users can switch accounts explicitly.
    try {
      await googleSignIn.signOut();
    } catch (_) {}

    // --- PASO 3: Lanzar la petición y abrir el selector
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return ref.read(authStateProvider);
    }

    // --- PASO 4: El Apretón de manos con Firebase
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    if (firebaseUser == null || firebaseUser.email == null) {
      throw Exception('No fue posible obtener datos del usuario de Google.');
    }

    // --- PASO 5: Extraer el Firebase ID Token (JWT Definitivo)
    final jwtToken = await firebaseUser.getIdToken();
    // Este token se puede imprimir, guardar en SecureStorage o inyectar a tu API
    print('✅ PASO 5 COMPLETADO: JWT Token obtenido: ${jwtToken?.substring(0, 20)}...');

    final command = LoginCommand(
      email: firebaseUser.email!,
      password: '',
      isGoogleSignIn: true,
    );

    // Mandamos siempre a login; el backend detecta si es la primera vez que
    // este Firebase UID aparece y devuelve isFirstLogin=true.
    await notifier.login(command);

    return ref.read(authStateProvider);
  }

  Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }
}
