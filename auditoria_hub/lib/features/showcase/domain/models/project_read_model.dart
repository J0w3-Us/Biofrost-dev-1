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
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
        teamName: json['teamName'] as String? ?? '',
        avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
        totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'active',
        coverImageUrl: json['coverImageUrl'] as String?,
        techStack: List<String>.from(json['techStack'] as List? ?? []),
        tags: List<String>.from(json['tags'] as List? ?? []),
      );

  @override
  List<Object?> get props => [id, title, avgScore, totalVotes, status];
}

/// Modelo para la lista paginada
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

  factory ProjectPageResult.fromJson(Map<String, dynamic> json) =>
      ProjectPageResult(
        items: (json['items'] as List)
            .map((e) => ProjectReadModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
        hasMore: json['hasMore'] as bool? ?? false,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [items, nextCursor, hasMore, total];
}
