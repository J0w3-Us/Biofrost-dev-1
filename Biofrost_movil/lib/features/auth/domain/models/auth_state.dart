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
    // Nuevos campos del backend
    this.isFirstLogin = false,
    this.grupoId,
    this.grupoNombre,
    this.matricula,
    this.carreraId,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.profesion,
    this.organizacion,
    this.especialidadDocente,
    this.createdAt,
    this.socialLinks,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;

  // Nuevos campos del backend
  final bool isFirstLogin;
  final String? grupoId;
  final String? grupoNombre;
  final String? matricula;
  final String? carreraId;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? profesion;
  final String? organizacion;
  final String? especialidadDocente;
  final String? createdAt;
  final Map<String, String>? socialLinks;

  // Getters tipados según el backend
  bool get isTeacher => role == 'Docente';
  bool get isStudent => role == 'Alumno';
  bool get isAdmin => role == 'SuperAdmin';
  bool get isGuest => role == 'Invitado';

  bool get needsCompleteProfile => isFirstLogin;
  String get fullName {
    final parts = [displayName, apellidoPaterno, apellidoMaterno]
        .where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  @override
  List<Object?> get props =>
      [uid, email, role, isFirstLogin, grupoId, matricula, carreraId];
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
