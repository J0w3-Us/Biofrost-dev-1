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

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return ref.read(authStateProvider);
    }

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

    await notifier.login(
      LoginCommand(
        email: firebaseUser.email!,
        password: '',
        isGoogleSignIn: true,
      ),
    );

    return ref.read(authStateProvider);
  }

  Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }
}
