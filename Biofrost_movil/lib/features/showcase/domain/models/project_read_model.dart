// features/showcase/domain/models/project_read_model.dart — ReadModel (CQRS Query)
import 'package:equatable/equatable.dart';

/// RF-02: Modelo de lectura optimizado para la galeria de proyectos
class ProjectReadModel extends Equatable {
  const ProjectReadModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.year,
    required this.teamName,
    required this.avgScore,
    required this.totalVotes,
    required this.status,
    this.coverImageUrl,
    this.techStack = const [],
    this.tags = const [],
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int year;
  final String teamName;
  final double avgScore;
  final int totalVotes;
  final String status;
  final String? coverImageUrl;
  final List<String> techStack;
  final List<String> tags;

  factory ProjectReadModel.fromJson(Map<String, dynamic> json) =>
      ProjectReadModel(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        // API devuelve 'titulo' (español); fallback a 'title'
        title: (json['titulo'] ?? json['title'] ?? 'Sin título').toString(),
        description: (json['descripcion'] ?? json['description'] ?? '').toString(),
        category: (json['materia'] ?? json['category'] ?? '').toString(),
        // 'ciclo' viene como "2026-1" → extraemos el año
        year: _parseYear(json['ciclo'] ?? json['year']),
        teamName: (json['liderNombre'] ?? json['teamName'] ?? json['nombre'] ?? '').toString(),
        avgScore: ((json['puntosTotales'] ?? json['calificacion'] ?? json['avgScore']) as num? ?? 0).toDouble(),
        totalVotes: ((json['conteoVotos'] ?? json['totalVotes']) as num? ?? 0).toInt(),
        status: (json['estado'] ?? json['status'] ?? 'active').toString(),
        coverImageUrl: (json['thumbnailUrl'] ?? json['coverImageUrl']) as String?,
        techStack: List<String>.from(
          (json['stackTecnologico'] ?? json['techStack']) as List? ?? [],
        ),
        tags: List<String>.from(json['tags'] as List? ?? []),
      );

  static int _parseYear(dynamic raw) {
    if (raw == null) return DateTime.now().year;
    if (raw is int) return raw;
    final s = raw.toString();
    // "2026-1" → 2026
    final match = RegExp(r'(\d{4})').firstMatch(s);
    if (match != null) return int.tryParse(match.group(1)!) ?? DateTime.now().year;
    return int.tryParse(s) ?? DateTime.now().year;
  }

  @override
  List<Object?> get props => [id, title, avgScore, totalVotes, status];
}

/// Modelo para la lista paginada — soporta array directo y objeto paginado
class ProjectPageResult extends Equatable {
  const ProjectPageResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.total,
  });

  final List<ProjectReadModel> items;
  final String? nextCursor;
  final bool hasMore;
  final int total;

  factory ProjectPageResult.fromJson(dynamic raw) {
    // Si el API devuelve un array directo (respuesta actual: [...])
    if (raw is List) {
      final items = <ProjectReadModel>[];
      for (final e in raw) {
        try {
          items.add(ProjectReadModel.fromJson(e as Map<String, dynamic>));
        } catch (_) {} // Ignora proyectos malformados
      }
      return ProjectPageResult(
        items: items,
        nextCursor: null,
        hasMore: false,
        total: items.length,
      );
    }
    // Si el API devuelve objeto paginado { items: [...], hasMore, nextCursor }
    final json = raw as Map<String, dynamic>;
    final items = <ProjectReadModel>[];
    for (final e in (json['items'] as List? ?? [])) {
      try {
        items.add(ProjectReadModel.fromJson(e as Map<String, dynamic>));
      } catch (_) {} // Ignora proyectos malformados
    }
    return ProjectPageResult(
      items: items,
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [items, nextCursor, hasMore, total];
}
