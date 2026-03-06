// features/project_detail/providers/project_detail_provider.dart — Optimistic Update
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../data/datasources/project_detail_remote_datasource.dart';
import '../domain/commands/submit_evaluation_command.dart';
import '../domain/models/project_detail_read_model.dart';

final projectDetailDatasourceProvider = Provider<ProjectDetailRemoteDatasource>(
  (ref) => ProjectDetailRemoteDatasource(ref.watch(dioProvider)),
);

// ── Estado del detalle ────────────────────────────────────────────────────
class ProjectDetailState {
  const ProjectDetailState({
    this.project,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.evalError,
    this.evalSuccess = false,
  });

  final ProjectDetailReadModel? project;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? evalError;
  final bool evalSuccess;

  ProjectDetailState copyWith({
    ProjectDetailReadModel? project,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? evalError,
    bool? evalSuccess,
  }) =>
      ProjectDetailState(
        project: project ?? this.project,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
        evalError: evalError,
        evalSuccess: evalSuccess ?? this.evalSuccess,
      );
}

final projectDetailProvider =
    NotifierProviderFamily<ProjectDetailNotifier, ProjectDetailState, String>(
        ProjectDetailNotifier.new);

class ProjectDetailNotifier extends FamilyNotifier<ProjectDetailState, String> {
  @override
  ProjectDetailState build(String projectId) {
    _load(projectId);
    return const ProjectDetailState(isLoading: true);
  }

  ProjectDetailRemoteDatasource get _ds =>
      ref.read(projectDetailDatasourceProvider);

  Future<void> _load(String id) async {
    try {
      final project = await _ds.getProjectDetail(id);
      state = state.copyWith(project: project, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Publico para recargar desde la UI
  Future<void> reload() => _load(arg);

  /// RF-04: Envio de evaluacion con Optimistic Update + Rollback
  Future<void> submitEvaluation(SubmitEvaluationCommand cmd) async {
    final prev = state;
    final project = state.project;
    if (project == null) return;

    // Optimistic update — refleja los cambios en UI inmediatamente
    state = state.copyWith(
      isSubmitting: true,
      evalError: null,
      evalSuccess: false,
    );

    try {
      await _ds.submitEvaluation(cmd);
      // Recarga el detalle para reflejar nuevo promedio
      final updated = await _ds.getProjectDetail(cmd.projectId);
      state = state.copyWith(
        project: updated,
        isSubmitting: false,
        evalSuccess: true,
      );
    } catch (e) {
      // Rollback automatico
      state = prev.copyWith(
        isSubmitting: false,
        evalError: e.toString(),
      );
    }
  }
}
