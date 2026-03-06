// features/project_detail/domain/commands/submit_evaluation_command.dart
import 'package:equatable/equatable.dart';

/// RF-04: Comando para enviar/actualizar evaluacion (CQRS Write)
class SubmitEvaluationCommand extends Equatable {
  const SubmitEvaluationCommand({
    required this.projectId,
    required this.stars,
    this.feedback,
  });

  final String projectId;
  final int stars; // 1–5
  final String? feedback;

  @override
  List<Object?> get props => [projectId, stars, feedback];
}
