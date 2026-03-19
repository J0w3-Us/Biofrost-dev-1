// features/auth/domain/commands/login_command.dart — CQRS Write commands
import 'package:equatable/equatable.dart';

/// RF-01: Comando para autenticación con email + password
class LoginCommand extends Equatable {
  const LoginCommand({
    required this.email,
    required this.password,
    this.isGoogleSignIn = false,
  });

  final String email;
  final String password;
  /// Si el login proviene de Google Sign-In (no requiere password local)
  final bool isGoogleSignIn;

  @override
  List<Object> get props => [email, password, isGoogleSignIn];
}

/// Asignación de carrera + materia + grupos (solo para Docente)
class DocenteAsignacion extends Equatable {
  const DocenteAsignacion({
    required this.carreraId,
    required this.materiaId,
    required this.gruposIds,
  });

  final String carreraId;
  final String materiaId;
  final List<String> gruposIds;

  Map<String, dynamic> toJson() => {
        'carreraId': carreraId,
        'materiaId': materiaId,
        'gruposIds': gruposIds,
      };

  @override
  List<Object> get props => [carreraId, materiaId, gruposIds];
}

/// Comando para registro de nuevo usuario
class RegisterCommand extends Equatable {
  const RegisterCommand({
    required this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    required this.email,
    required this.password,
    required this.rol,
    this.profesion,
    this.organizacion,
    // Docente: lista de asignaciones (carrera + materia + grupos)
    this.asignaciones = const [],
  });

  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String email;
  final String password;
  final String rol; // "Docente", "Alumno", "Invitado"
  final String? profesion; // Solo para Docente
  final String? organizacion; // Solo para Invitado
  /// Asignaciones del docente — corresponde 1:1 con el backend C#
  final List<DocenteAsignacion> asignaciones;

  @override
  List<Object?> get props => [
        nombre,
        apellidoPaterno,
        apellidoMaterno,
        email,
        password,
        rol,
        profesion,
        organizacion,
        asignaciones,
      ];
}

/// Comando para completar perfil de usuario ya autenticado (isFirstLogin)
class CompleteProfileCommand extends Equatable {
  const CompleteProfileCommand({
    required this.firebaseUid,
    required this.email,
    required this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    required this.rol,
    this.profesion,
    this.organizacion,
    this.asignaciones = const [],
  });

  final String firebaseUid;
  final String email;
  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String rol;
  final String? profesion;
  final String? organizacion;
  final List<DocenteAsignacion> asignaciones;

  @override
  List<Object?> get props => [
        firebaseUid,
        email,
        nombre,
        apellidoPaterno,
        apellidoMaterno,
        rol,
        profesion,
        organizacion,
        asignaciones,
      ];
}

/// Detector de roles basado en email
class RoleDetector {
  static String fromEmail(String email) {
    final lowerEmail = email.toLowerCase().trim();

    if (lowerEmail.contains('admin') &&
        lowerEmail.endsWith('@utmetropolitana.edu.mx')) {
      return 'SuperAdmin';
    }
    if (lowerEmail.endsWith('@alumno.utmetropolitana.edu.mx')) {
      return 'Alumno';
    }
    if (lowerEmail.endsWith('@utmetropolitana.edu.mx') ||
        lowerEmail.endsWith('@utm.mx')) {
      return 'Docente';
    }
    return 'Invitado';
  }
}
