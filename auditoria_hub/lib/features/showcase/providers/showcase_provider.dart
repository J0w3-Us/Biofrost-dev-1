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

class ShowcaseNotifier extends Notifier<ShowcaseState> {
  @override
  ShowcaseState build() {
    load();
    return const ShowcaseState(isLoading: true);
  }

  ShowcaseRemoteDatasource get _ds => ref.read(showcaseDatasourceProvider);
  ShowcaseFilters get _filters => ref.read(showcaseFiltersProvider);

  /// Carga inicial o recarga
  Future<void> load({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: !refresh,
      isRefreshing: refresh,
      error: null,
    );

    try {
      final result = await _ds.getProjects(
        search: _filters.search,
        category: _filters.category,
        year: _filters.year,
      );

      state = state.copyWith(
        projects: result.items,
        hasMore: result.hasMore,
        cursor: result.nextCursor,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
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
        search: _filters.search,
        category: _filters.category,
        year: _filters.year,
      );

      state = state.copyWith(
        projects: [...state.projects, ...result.items],
        hasMore: result.hasMore,
        cursor: result.nextCursor,
      );
    } catch (_) {}
  }

  /// Aplica filtros y recarga
  void applyFilter(ShowcaseFilters filters) {
    ref.read(showcaseFiltersProvider.notifier).state = filters;
    load(refresh: true);
  }
}
