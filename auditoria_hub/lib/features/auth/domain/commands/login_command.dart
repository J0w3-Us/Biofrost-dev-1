// features/auth/domain/commands/login_command.dart — Comando de login (CQRS Write)
import 'package:equatable/equatable.dart';

/// RF-01: Comando para autenticacion con email + password
class LoginCommand extends Equatable {
  const LoginCommand({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
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
    this.carrerasIds = const [],
    this.gruposDocente = const [],
  });

  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String email;
  final String password;
  final String rol; // "Docente", "Alumno", "Invitado"
  final String? profesion; // Solo para Docente
  final String? organizacion; // Solo para Invitado
  final List<String> carrerasIds; // Solo para Docente
  final List<String> gruposDocente; // Solo para Docente

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
        carrerasIds,
        gruposDocente,
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
