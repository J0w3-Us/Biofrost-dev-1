// features/dashboard/domain/models/teacher_project_model.dart
import 'package:equatable/equatable.dart';

/// Modelo de proyecto para el dashboard del docente.
/// Mapea la respuesta de GET /api/projects/teacher/{id}
class TeacherProjectModel extends Equatable {
  const TeacherProjectModel({
    required this.id,
    required this.titulo,
    required this.estado,
    required this.liderId,
    required this.esPublico,
    this.materia,
    this.liderNombre,
    this.thumbnailUrl,
    this.calificacion,
    this.stackTecnologico = const [],
    this.membersCount = 0,
  });

  final String id;
  final String titulo;
  final String estado;
  final String liderId;
  final bool esPublico;
  final String? materia;
  final String? liderNombre;
  final String? thumbnailUrl;
  final double? calificacion;
  final List<String> stackTecnologico;
  final int membersCount;

  bool get pendienteDeEvaluar => esPublico && calificacion == null;
  bool get aprobado => calificacion != null && calificacion! >= 70;

  factory TeacherProjectModel.fromJson(Map<String, dynamic> j) {
    return TeacherProjectModel(
      id: j['id'] as String? ?? j['Id'] as String? ?? '',
      titulo: j['titulo'] as String? ?? j['Titulo'] as String? ?? 'Sin título',
      estado: j['estado'] as String? ?? j['Estado'] as String? ?? '',
      liderId: j['liderId'] as String? ?? j['LiderId'] as String? ?? '',
      esPublico: j['esPublico'] as bool? ?? j['EsPublico'] as bool? ?? false,
      materia: j['materia'] as String? ?? j['Materia'] as String?,
      liderNombre: j['liderNombre'] as String? ?? j['LiderNombre'] as String?,
      thumbnailUrl:
          j['thumbnailUrl'] as String? ?? j['ThumbnailUrl'] as String?,
      calificacion:
          (j['calificacion'] ?? j['Calificacion'] as num?)?.toDouble(),
      stackTecnologico: List<String>.from(j['stackTecnologico'] as List? ??
          j['StackTecnologico'] as List? ??
          []),
      membersCount:
          (j['membersCount'] ?? j['MembersCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, titulo, esPublico, calificacion];
}
