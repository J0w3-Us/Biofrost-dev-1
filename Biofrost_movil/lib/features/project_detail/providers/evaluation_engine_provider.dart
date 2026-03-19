import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/project_detail_read_model.dart';
import 'project_detail_provider.dart';

class EvaluationEngineState {
  const EvaluationEngineState({
    required this.criteria,
    required this.weightedTotalScore,
    required this.progress,
    required this.status,
  });

  final List<CriterionReadModel> criteria;
  final double weightedTotalScore;
  final double progress;
  final EvaluationStatus status;

  bool get isComplete =>
      criteria.isNotEmpty && criteria.every((c) => c.score > 0);
  bool get hasAnyScore => criteria.any((c) => c.score > 0);

  EvaluationEngineState copyWith({
    List<CriterionReadModel>? criteria,
    double? weightedTotalScore,
    double? progress,
    EvaluationStatus? status,
  }) {
    return EvaluationEngineState(
      criteria: criteria ?? this.criteria,
      weightedTotalScore: weightedTotalScore ?? this.weightedTotalScore,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}

final evaluationEngineProvider = NotifierProviderFamily<
    EvaluationEngineNotifier, EvaluationEngineState, String>(
  EvaluationEngineNotifier.new,
);

class EvaluationEngineNotifier
    extends FamilyNotifier<EvaluationEngineState, String> {
  @override
  EvaluationEngineState build(String projectId) {
    final eval =
        ref.read(projectDetailProvider(projectId)).project?.myEvaluation;
    final seededCriteria = _seedCriteria(eval);
    return _computeState(
      criteria: seededCriteria,
      status: eval?.status ?? EvaluationStatus.draft,
    );
  }

  void hydrateFromEvaluation(EvaluationReadModel? eval) {
    if (eval == null) return;
    if (state.hasAnyScore) return;

    state = _computeState(
      criteria: _seedCriteria(eval),
      status: eval.status,
    );
  }

  void updateCriterionScore(String criterionId, int score) {
    final safeScore = score.clamp(1, 5).toDouble();
    final updated = state.criteria
        .map((c) => c.id == criterionId ? c.copyWith(score: safeScore) : c)
        .toList(growable: false);

    state = _computeState(
      criteria: updated,
      status: EvaluationStatus.draft,
    );
  }

  void updateCriterionComment(String criterionId, String comment) {
    final normalized = comment.trim();
    final updated = state.criteria
        .map(
          (c) => c.id == criterionId
              ? c.copyWith(comment: normalized.isEmpty ? null : normalized)
              : c,
        )
        .toList(growable: false);

    state = _computeState(
      criteria: updated,
      status: EvaluationStatus.draft,
    );
  }

  void setDraftStatus() {
    state = state.copyWith(status: EvaluationStatus.draft);
  }

  void setCompletedStatus() {
    state = state.copyWith(status: EvaluationStatus.completed);
  }

  List<CriterionReadModel> _seedCriteria(EvaluationReadModel? eval) {
    if (eval != null && eval.criteria.isNotEmpty) {
      return eval.criteria;
    }

    return const [
      CriterionReadModel(
        id: 'innovacion',
        name: 'Innovacion',
        weight: 0.25,
        score: 0,
      ),
      CriterionReadModel(
        id: 'viabilidad',
        name: 'Viabilidad tecnica',
        weight: 0.25,
        score: 0,
      ),
      CriterionReadModel(
        id: 'impacto',
        name: 'Impacto',
        weight: 0.25,
        score: 0,
      ),
      CriterionReadModel(
        id: 'presentacion',
        name: 'Presentacion',
        weight: 0.25,
        score: 0,
      ),
    ];
  }

  EvaluationEngineState _computeState({
    required List<CriterionReadModel> criteria,
    required EvaluationStatus status,
  }) {
    final ratedCount = criteria.where((c) => c.score > 0).length;
    final hasRatedAny = ratedCount > 0;

    // Score ponderado bruto: suma de (score × weight).
    // Los pesos están normalizados y suman 1.0, por lo que el resultado
    // está en la escala [0.0, 5.0] (escala de rúbrica de criterios 1–5).
    // El Datasource/Adaptador es el único responsable de convertir este
    // valor a la escala 0–100 que exige la API legada.
    final weightedTotalScore = criteria.fold<double>(
      0.0,
      (sum, c) => sum + (c.score * c.weight),
    );

    // Progress: se muestra en la UI como porcentaje de la escala 0–5.
    // Se convierte a 0–100 solo para la barra de progreso visual.
    final progressPercent = hasRatedAny
        ? (weightedTotalScore / 5.0 * 100).clamp(0.0, 100.0)
        : 0.0;

    return EvaluationEngineState(
      criteria: criteria,
      weightedTotalScore: weightedTotalScore,
      progress: progressPercent,
      status: status,
    );
  }
}
