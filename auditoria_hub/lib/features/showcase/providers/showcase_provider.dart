// features/showcase/providers/showcase_provider.dart — Stale-While-Revalidate
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../data/datasources/showcase_remote_datasource.dart';
import '../domain/models/project_read_model.dart';

// ── Datasource provider ───────────────────────────────────────────────────
final showcaseDatasourceProvider = Provider<ShowcaseRemoteDatasource>(
  (ref) => ShowcaseRemoteDatasource(ref.watch(dioProvider)),
);

// ── Filtros activos ───────────────────────────────────────────────────────
class ShowcaseFilters {
  const ShowcaseFilters({this.search = '', this.category, this.year});
  final String search;
  final String? category;
  final int? year;

  ShowcaseFilters copyWith({String? search, String? category, int? year}) =>
      ShowcaseFilters(
        search: search ?? this.search,
        category: category ?? this.category,
        year: year ?? this.year,
      );
}

final showcaseFiltersProvider =
    StateProvider<ShowcaseFilters>((_) => const ShowcaseFilters());

// ── Estado de la lista ────────────────────────────────────────────────────
class ShowcaseState {
  const ShowcaseState({
    this.projects = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final List<ProjectReadModel> projects;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final String? cursor;
  final String? error;

  ShowcaseState copyWith({
    List<ProjectReadModel>? projects,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    String? cursor,
    String? error,
  }) =>
      ShowcaseState(
        projects: projects ?? this.projects,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor,
        error: error,
      );
}

final showcaseProvider =
    NotifierProvider<ShowcaseNotifier, ShowcaseState>(ShowcaseNotifier.new);

// ── Provider de proyectos filtrados (Local) ───────────────────────────────
final filteredProjectsProvider = Provider<List<ProjectReadModel>>((ref) {
  final projects = ref.watch(showcaseProvider).projects;
  final filters = ref.watch(showcaseFiltersProvider);

  var list = projects;
  final q = filters.search.toLowerCase();
  
  if (q.isNotEmpty) {
    list = list.where((p) => 
      p.title.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q) ||
      p.teamName.toLowerCase().contains(q) ||
      p.techStack.any((t) => t.toLowerCase().contains(q)) ||
      p.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  if (filters.category != null && filters.category!.isNotEmpty) {
    list = list.where((p) => p.techStack.contains(filters.category)).toList();
  }

  return list;
});

class ShowcaseNotifier extends Notifier<ShowcaseState> {
  @override
  ShowcaseState build() {
    // FIX: Usar Future.microtask para que load() corra DESPUÉS de que
    // build() retorne y establezca el estado inicial isLoading:true.
    // Esto evita la race condition donde load() lee isLoading:true del
    // estado previo y sale sin hacer nada.
    Future.microtask(() => _loadInitial());
    return const ShowcaseState(isLoading: true);
  }

  ShowcaseRemoteDatasource get _ds => ref.read(showcaseDatasourceProvider);
  ShowcaseFilters get _filters => ref.read(showcaseFiltersProvider);

  /// Carga inicial — siempre ejecuta sin guard
  Future<void> _loadInitial() async {
    state = const ShowcaseState(isLoading: true);
    try {
      final result = await _ds.getProjects(
        // Los filtros ahora son locales para esta version p/ evitar llamadas innecesarias al API
        // si el API es un array directo.
      );
      state = ShowcaseState(
        projects: result.items,
        hasMore: result.hasMore,
        cursor: result.nextCursor,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      state = ShowcaseState(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// Carga inicial o recarga
  Future<void> load({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
    );

    try {
      final result = await _ds.getProjects();

      state = state.copyWith(
        projects: result.items,
        hasMore: result.hasMore,
        cursor: result.nextCursor,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      // FIX: Captura cualquier excepción (no solo DioException) para evitar
      // que el estado quede en isLoading:true indefinidamente.
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// Infinite scroll — carga siguiente pagina
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    try {
      final result = await _ds.getProjects(
        cursor: state.cursor,
      );

      state = state.copyWith(
        projects: [...state.projects, ...result.items],
        hasMore: result.hasMore,
        cursor: result.nextCursor,
      );
    } catch (_) {}
  }

  /// Aplica filtros localmente sin recargar de API
  void applyFilter(ShowcaseFilters filters) {
    ref.read(showcaseFiltersProvider.notifier).state = filters;
  }
}
