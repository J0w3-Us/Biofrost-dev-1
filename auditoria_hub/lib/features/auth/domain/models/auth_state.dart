// features/auth/domain/models/auth_state.dart — Estados de sesion (sealed class)
import 'package:equatable/equatable.dart';

/// RF-01: Autenticacion con Firebase Auth + JWT de la API
sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;

  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, email, role];
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
