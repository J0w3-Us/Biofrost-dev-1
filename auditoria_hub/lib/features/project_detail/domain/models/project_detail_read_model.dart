// features/project_detail/domain/models/project_detail_read_model.dart
import 'package:equatable/equatable.dart';

/// RF-03: ReadModel detallado de un proyecto
class ProjectDetailReadModel extends Equatable {
  const ProjectDetailReadModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.year,
    required this.teamName,
    required this.teamMembers,
    required this.avgScore,
    required this.totalVotes,
    required this.status,
    required this.techStack,
    this.coverImageUrl,
    this.videoUrl,
    this.myEvaluation,
    this.evaluations = const [],
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int year;
  final String teamName;
  final List<String> teamMembers;
  final double avgScore;
  final int totalVotes;
  final String status;
  final List<String> techStack;
  final String? coverImageUrl;
  final String? videoUrl;
  final EvaluationReadModel? myEvaluation;
  final List<EvaluationReadModel> evaluations;

  factory ProjectDetailReadModel.fromJson(Map<String, dynamic> json) =>
      ProjectDetailReadModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
        teamName: json['teamName'] as String? ?? '',
        teamMembers: List<String>.from(json['teamMembers'] as List? ?? []),
        avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
        totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'active',
        techStack: List<String>.from(json['techStack'] as List? ?? []),
        coverImageUrl: json['coverImageUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        myEvaluation: json['myEvaluation'] != null
            ? EvaluationReadModel.fromJson(
                json['myEvaluation'] as Map<String, dynamic>)
            : null,
        evaluations: (json['evaluations'] as List? ?? [])
            .map((e) => EvaluationReadModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [id, avgScore, totalVotes, myEvaluation];
}

class EvaluationReadModel extends Equatable {
  const EvaluationReadModel({
    required this.id,
    required this.evaluatorName,
    required this.stars,
    this.feedback,
    required this.createdAt,
  });

  final String id;
  final String evaluatorName;
  final int stars;
  final String? feedback;
  final DateTime createdAt;

  factory EvaluationReadModel.fromJson(Map<String, dynamic> json) =>
      EvaluationReadModel(
        id: json['id'] as String,
        evaluatorName: json['evaluatorName'] as String? ?? 'Anónimo',
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        feedback: json['feedback'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [id, stars, createdAt];
}
