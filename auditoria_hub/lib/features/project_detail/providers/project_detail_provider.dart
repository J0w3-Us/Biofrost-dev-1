// features/project_detail/providers/project_detail_provider.dart — Optimistic Update + Offline
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/services/api_service.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
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
    this.fromCache = false,
  });

  final ProjectDetailReadModel? project;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? evalError;
  final bool evalSuccess;

  /// true si los datos provienen del caché local
  final bool fromCache;

  ProjectDetailState copyWith({
    ProjectDetailReadModel? project,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? evalError,
    bool? evalSuccess,
    bool? fromCache,
  }) =>
      ProjectDetailState(
        project: project ?? this.project,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
        evalError: evalError,
        evalSuccess: evalSuccess ?? this.evalSuccess,
        fromCache: fromCache ?? this.fromCache,
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
  bool get _isOnline => ref.read(isOnlineProvider);

  Future<void> _load(String id) async {
    final auth = ref.read(authStateProvider);
    final uid = auth is AuthAuthenticated ? auth.uid : null;
    try {
      final project = await _ds.getProjectDetail(
        id,
        isOnline: _isOnline,
        currentUserId: uid,
      );
      state = state.copyWith(
        project: project,
        isLoading: false,
        fromCache: !_isOnline,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Público para recargar desde la UI
  Future<void> reload() => _load(arg);

  /// RF-04: Envío de evaluación con Optimistic Update + Rollback
  Future<void> submitEvaluation(SubmitEvaluationCommand cmd) async {
    if (!_isOnline) {
      state = state.copyWith(
        evalError: 'Necesitas conexión a internet para evaluar un proyecto.',
      );
      return;
    }

    // Obtener datos de autenticación para construir el body del backend
    final auth = ref.read(authStateProvider);
    if (auth is! AuthAuthenticated) {
      state = state.copyWith(evalError: 'Debes iniciar sesión para evaluar.');
      return;
    }

    final prev = state;
    if (state.project == null) return;

    state = state.copyWith(
      isSubmitting: true,
      evalError: null,
      evalSuccess: false,
    );

    try {
      await _ds.submitEvaluation(
        projectId: cmd.projectId,
        docenteId: auth.uid,
        docenteNombre: auth.displayName,
        // Docentes → "oficial" (calificación 0-100); invitados → "sugerencia"
        tipo: auth.isTeacher ? 'oficial' : 'sugerencia',
        stars: cmd.stars,
        feedback: cmd.feedback,
      );
      // Recarga el detalle con uid para resolver myEvaluation
      final updated = await _ds.getProjectDetail(
        cmd.projectId,
        isOnline: true,
        currentUserId: auth.uid,
      );
      state = state.copyWith(
        project: updated,
        isSubmitting: false,
        evalSuccess: true,
        fromCache: false,
      );
    } catch (e) {
      // Rollback automático
      state = prev.copyWith(
        isSubmitting: false,
        evalError: e is AppException ? e.message : e.toString(),
      );
    }
  }

  /// Alterna la visibilidad pública/privada de una evaluación.
  Future<void> toggleVisibility(String evalId, bool esPublico) async {
    if (!_isOnline) {
      state = state.copyWith(
        evalError: 'Necesitas conexión para cambiar la visibilidad.',
      );
      return;
    }
    final auth = ref.read(authStateProvider);
    if (auth is! AuthAuthenticated) return;

    try {
      await _ds.toggleVisibility(
        evalId: evalId,
        userId: auth.uid,
        esPublico: esPublico,
      );
      // Recarga para reflejar el cambio
      await _load(arg);
    } catch (e) {
      state = state.copyWith(
        evalError: e is AppException ? e.message : e.toString(),
      );
    }
  }
}
