// features/showcase/providers/showcase_provider.dart
// Patrón: Offline-First — Single Source of Truth = SQLite
//
// Flujo:
//   build() → suscribe a LocalRepo.watch() → UI muestra caché inmediatamente
//          → _syncIfStale() → si stale/vacío → RemoteRepo.fetch() → LocalRepo.save()
//          → stream emite → UI actualiza sin reconstruir Notifier
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_database.dart';
import '../../../core/cache/cache_policy.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/services/api_service.dart';
import '../data/repositories/showcase_local_repository.dart';
import '../data/repositories/showcase_remote_repository.dart';
import '../domain/models/project_read_model.dart';

// ── Providers de los Repositorios ────────────────────────────────────────────

final showcaseLocalRepoProvider = Provider<ShowcaseLocalRepository>((ref) {
  return ShowcaseLocalRepository(CacheDatabase.instance);
});

final showcaseRemoteRepoProvider = Provider<ShowcaseRemoteRepository>((ref) {
  return ShowcaseRemoteRepository(ref.watch(dioProvider));
});

// ── Filtros activos ───────────────────────────────────────────────────────────
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

// ── Estado ───────────────────────────────────────────────────────────────────

class ShowcaseState {
  const ShowcaseState({
    this.projects = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSyncing = false,
    this.hasMore = true,
    this.cursor,
    this.error,
    this.fromCache = false,
  });

  final List<ProjectReadModel> projects;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSyncing;
  final bool hasMore;
  final String? cursor;
  final String? error;

  /// true si los datos provienen del caché local (sin confirmación de red reciente).
  final bool fromCache;

  ShowcaseState copyWith({
    List<ProjectReadModel>? projects,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSyncing,
    bool? hasMore,
    String? cursor,
    String? error,
    bool? fromCache,
  }) =>
      ShowcaseState(
        projects: projects ?? this.projects,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isSyncing: isSyncing ?? this.isSyncing,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor,
        error: error,
        fromCache: fromCache ?? this.fromCache,
      );
}

// ── Provider de la lista filtrada (solo en memoria, nunca toca red) ───────────

final filteredProjectsProvider = Provider<List<ProjectReadModel>>((ref) {
  final projects = ref.watch(showcaseProvider).projects;
  final filters = ref.watch(showcaseFiltersProvider);

  var list = projects;
  final q = filters.search.toLowerCase();

  if (q.isNotEmpty) {
    list = list
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.teamName.toLowerCase().contains(q) ||
            p.techStack.any((t) => t.toLowerCase().contains(q)) ||
            p.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  if (filters.category != null && filters.category!.isNotEmpty) {
    list = list.where((p) => p.techStack.contains(filters.category)).toList();
  }

  return list;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

final showcaseProvider =
    NotifierProvider<ShowcaseNotifier, ShowcaseState>(ShowcaseNotifier.new);

class ShowcaseNotifier extends Notifier<ShowcaseState> {
  StreamSubscription<List<ProjectReadModel>>? _localSub;

  @override
  ShowcaseState build() {
    ref.onDispose(() {
      _localSub?.cancel();
    });

    // Inicia el flujo Offline-First después de que build() retorne
    Future.microtask(() => _initialize());
    return const ShowcaseState(isLoading: true);
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  ShowcaseLocalRepository get _localRepo =>
      ref.read(showcaseLocalRepoProvider);
  ShowcaseRemoteRepository get _remoteRepo =>
      ref.read(showcaseRemoteRepoProvider);
  bool get _isOnline => ref.read(isOnlineProvider);

  void _initialize() {
    // 1. Suscribirse al stream de SQLite
    _localSub = _localRepo.watch().listen(_onLocalData);

    // 2. Sincronizar si el caché está stale o vacío
    _syncIfStale();
  }

  void _onLocalData(List<ProjectReadModel> projects) {
    if (projects.isNotEmpty) {
      state = state.copyWith(
        projects: projects,
        isLoading: false,
        isRefreshing: false,
        error: null,
      );
    } else if (!state.isSyncing) {
      // BD vacía y sin sync activo → no hay datos aún
      state = state.copyWith(isLoading: false, isRefreshing: false);
    }
  }

  void _syncIfStale() {
    _localRepo.getFetchedAt().then((fetchedAt) {
      final needsSync =
          fetchedAt == null || isCacheStale(fetchedAt, kShowcaseCacheMaxAge);
      if (needsSync) _syncFromRemote();
    });
  }

  Future<void> _syncFromRemote() async {
    if (!_isOnline) {
      final hasLocal = await _localRepo.hasData();
      if (!hasLocal) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: 'Sin conexión y sin datos guardados.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          fromCache: true,
        );
      }
      return;
    }

    state = state.copyWith(isSyncing: true);
    try {
      final raw = await _remoteRepo.fetchProjects();
      await _localRepo.saveProjects(raw);
      // El stream emite automáticamente → _onLocalData actualiza la UI
      state = state.copyWith(
        isSyncing: false,
        fromCache: false,
        isRefreshing: false,
      );
    } catch (_) {
      final hasLocal = await _localRepo.hasData();
      state = state.copyWith(
        isSyncing: false,
        isLoading: false,
        isRefreshing: false,
        fromCache: hasLocal,
        error: hasLocal ? null : 'Error al cargar los proyectos.',
      );
    }
  }

  // ── Acciones públicas ─────────────────────────────────────────────────────

  /// Pull-to-refresh: fuerza recarga completa desde la red.
  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    }
    await _syncFromRemote();
  }

  /// Aplica filtros localmente sin llamar a la red.
  void applyFilter(ShowcaseFilters filters) {
    ref.read(showcaseFiltersProvider.notifier).state = filters;
  }

  /// Infinite scroll — carga siguiente página (solo si la API la soporta).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isSyncing) return;
    if (!_isOnline) return;

    try {
      final raw = await _remoteRepo.fetchProjects(
        cursor: state.cursor,
      );

      // Para paginación, el response debe ser un Map con 'items' y 'nextCursor'.
      // Si es un array plano, no hay más páginas.
      if (raw is List) {
        state = state.copyWith(hasMore: false);
        return;
      }
      if (raw is Map<String, dynamic>) {
        final result = ProjectPageResult.fromJson(raw);
        // Mezclar con los existentes en memoria (sin borrar SQLite)
        state = state.copyWith(
          projects: [...state.projects, ...result.items],
          hasMore: result.hasMore,
          cursor: result.nextCursor,
        );
      }
    } catch (_) {
      // Error silencioso en paginación
    }
  }
}
