// features/project_detail/domain/models/project_detail_read_model.dart
import 'package:collection/collection.dart';
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

  factory ProjectDetailReadModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // ciclo: "2024-A" → extraer año
    final ciclo = json['ciclo'] as String? ?? '';
    final year =
        int.tryParse(ciclo.length >= 4 ? ciclo.substring(0, 4) : ciclo) ??
            DateTime.now().year;

    // avgScore: puntosTotales/conteoVotos; fallback a calificacion
    final puntos = (json['puntosTotales'] as num?)?.toDouble() ?? 0.0;
    final votos = (json['conteoVotos'] as num?)?.toInt() ?? 0;
    final avgScore = votos > 0
        ? puntos / votos
        : (json['calificacion'] as num?)?.toDouble() ?? 0.0;

    // members: List<{id,nombre,email,fotoUrl,rol}> → extraer nombres
    final membersList =
        (json['members'] as List? ?? []).cast<Map<String, dynamic>>();
    final teamMembers = membersList
        .map((m) => m['nombre'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final leaderName = membersList
            .where((m) => m['rol'] == 'Líder')
            .map((m) => m['nombre'] as String? ?? '')
            .firstOrNull ??
        (teamMembers.isNotEmpty ? teamMembers.first : '');

    // canvas: extraer descripción del primer bloque de texto
    final canvas = (json['canvas'] as List? ?? []).cast<Map<String, dynamic>>();
    const textTypes = ['text', 'h1', 'h2', 'h3', 'quote', 'bullet', 'todo'];
    final firstTextBlock = canvas.firstWhereOrNull(
      (b) => textTypes.contains(b['type']),
    );
    final rawContent = firstTextBlock?['content'] as String? ?? '';
    // Eliminar etiquetas HTML simples
    final description = rawContent.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    // evaluaciones del backend (lista plana de EvaluationDto)
    final evalList = (json['evaluations'] as List? ?? [])
        .map((e) => EvaluationReadModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // myEvaluation: encontrar la del usuario actual por docenteId
    EvaluationReadModel? myEval;
    if (currentUserId != null) {
      final rawEvals =
          (json['evaluations'] as List? ?? []).cast<Map<String, dynamic>>();
      final mine = rawEvals.firstWhereOrNull(
        (e) => e['docenteId'] == currentUserId,
      );
      if (mine != null) myEval = EvaluationReadModel.fromJson(mine);
    }

    return ProjectDetailReadModel(
      id: json['id'] as String,
      title: json['titulo'] as String? ?? '',
      description: description,
      category: json['materia'] as String? ?? '',
      year: year,
      teamName: leaderName,
      teamMembers: teamMembers,
      avgScore: avgScore,
      totalVotes: votos,
      status: json['estado'] as String? ?? 'active',
      techStack: List<String>.from(json['stackTecnologico'] as List? ?? []),
      // thumbnailUrl no viene en ProjectDetailsDto; buscar en canvas
      coverImageUrl: json['thumbnailUrl'] as String? ??
          canvas.firstWhereOrNull((b) => b['type'] == 'image')?['url']
              as String?,
      videoUrl: json['videoUrl'] as String?,
      myEvaluation: myEval,
      evaluations: evalList,
    );
  }

  @override
  List<Object?> get props => [id, avgScore, totalVotes, myEvaluation];
}

enum EvaluationStatus { draft, completed }

class CriterionReadModel extends Equatable {
  const CriterionReadModel({
    required this.id,
    required this.name,
    required this.weight,
    required this.score,
    this.comment,
  });

  final String id;
  final String name;
  final double weight;
  final double score;
  final String? comment;

  factory CriterionReadModel.fromJson(Map<String, dynamic> json) {
    return CriterionReadModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      comment: (json['comment'] ?? json['comentario']) as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'score': score,
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment,
    };
  }

  CriterionReadModel copyWith({
    String? id,
    String? name,
    double? weight,
    double? score,
    String? comment,
  }) {
    return CriterionReadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      score: score ?? this.score,
      comment: comment ?? this.comment,
    );
  }

  @override
  List<Object?> get props => [id, name, weight, score, comment];
}

class EvaluationReadModel extends Equatable {
  const EvaluationReadModel({
    required this.id,
    required this.evaluatorId,
    required this.evaluatorName,
    required this.criteria,
    required this.weightedTotalScore,
    required this.status,
    required this.esPublico,
    required this.tipo,
    required this.createdAt,
  });

  final String id;
  final String evaluatorId;
  final String evaluatorName;
  final List<CriterionReadModel> criteria;
  final double weightedTotalScore;
  final EvaluationStatus status;
  final bool esPublico;
  final String tipo;
  final DateTime createdAt;

  factory EvaluationReadModel.fromJson(Map<String, dynamic> json) {
    final criteriaJson = json['criteria'] as List? ?? [];
    final weighted =
        (json['weightedTotalScore'] ?? json['calificacion'] ?? 0) as num;

    final criteria = criteriaJson.isNotEmpty
        ? criteriaJson
            .map((c) => CriterionReadModel.fromJson(c as Map<String, dynamic>))
            .toList()
        : [
            // Compatibilidad con payload legado de calificacion plana.
            CriterionReadModel(
              id: 'legacy_total',
              name: 'Evaluación general',
              weight: 1,
              score: (weighted.toDouble() / 20).clamp(0, 5),
            ),
          ];

    final statusStr = json['status'] as String?;
    final status = switch (statusStr) {
      'completed' => EvaluationStatus.completed,
      'draft' => EvaluationStatus.draft,
      _ => weighted.toDouble() > 0
          ? EvaluationStatus.completed
          : EvaluationStatus.draft,
    };

    return EvaluationReadModel(
      id: json['id'] as String,
      evaluatorId: json['docenteId'] as String? ?? '',
      evaluatorName: json['docenteNombre'] as String? ?? 'Anónimo',
      criteria: criteria,
      weightedTotalScore: weighted.toDouble(),
      status: status,
      esPublico: json['esPublico'] as bool? ?? false,
      tipo: json['tipo'] as String? ?? 'evaluacion',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'docenteId': evaluatorId,
      'docenteNombre': evaluatorName,
      'criteria': criteria.map((c) => c.toMap()).toList(),
      'weightedTotalScore': weightedTotalScore,
      'status': status.name,
      'esPublico': esPublico,
      'tipo': tipo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, criteria, weightedTotalScore, status, createdAt, esPublico];
}
