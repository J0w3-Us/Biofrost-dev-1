// features/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/services/api_service.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/teacher_project_model.dart';

// ── Estado ─────────────────────────────────────────────────────────────────
class DashboardState {
  const DashboardState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TeacherProjectModel> projects;
  final bool isLoading;
  final String? error;

  int get total => projects.length;
  int get pendientes => projects.where((p) => p.pendienteDeEvaluar).length;
  int get aprobados => projects.where((p) => p.aprobado).length;

  DashboardState copyWith({
    List<TeacherProjectModel>? projects,
    bool? isLoading,
    String? error,
  }) =>
      DashboardState(
        projects: projects ?? this.projects,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Provider ───────────────────────────────────────────────────────────────
final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    _load();
    return const DashboardState(isLoading: true);
  }

  Future<void> _load() async {
    final auth = ref.read(authStateProvider);
    if (auth is! AuthAuthenticated) {
      state = const DashboardState();
      return;
    }
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.teacherProjects(auth.uid));
      final list = (response.data as List? ?? [])
          .map((e) => TeacherProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = DashboardState(projects: list);
    } catch (e) {
      state = DashboardState(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Recarga manual (pull-to-refresh)
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _load();
  }
}
