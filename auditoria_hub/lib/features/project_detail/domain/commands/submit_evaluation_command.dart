// features/project_detail/domain/commands/submit_evaluation_command.dart
import 'package:equatable/equatable.dart';

import '../models/project_detail_read_model.dart';

/// RF-04: Comando para enviar/actualizar evaluacion (CQRS Write)
class SubmitEvaluationCommand extends Equatable {
  const SubmitEvaluationCommand({
    required this.projectId,
    required this.criteria,
    required this.weightedTotalScore,
    required this.status,
  });

  final String projectId;
  final List<CriterionReadModel> criteria;
  final double weightedTotalScore;
  final EvaluationStatus status;

  @override
  List<Object?> get props => [projectId, criteria, weightedTotalScore, status];
}
