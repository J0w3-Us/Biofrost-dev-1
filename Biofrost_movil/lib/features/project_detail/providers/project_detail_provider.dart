// features/project_detail/providers/project_detail_provider.dart
// Patrón: Offline-First — Single Source of Truth = SQLite
//
// Flujo:
//   build() → suscribe a LocalRepo.watch() → UI ve caché inmediatamente
//          → dispara _syncFromRemote() en background (no awaited)
//          → RemoteRepo.fetchDetail() → LocalRepo.saveDetail() → stream emite → UI actualiza
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_database.dart';
import '../../../core/cache/cache_policy.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/sync/outbox_item.dart';
import '../../../core/sync/sync_worker.dart';
import '../../auth/domain/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/project_detail_local_repository.dart';
import '../data/repositories/project_detail_remote_repository.dart';
import '../domain/commands/submit_evaluation_command.dart';
import '../domain/models/project_detail_read_model.dart';

// ── Providers de los Repositorios ────────────────────────────────────────────

final projectDetailLocalRepoProvider =
    Provider<ProjectDetailLocalRepository>((ref) {
  return ProjectDetailLocalRepository(CacheDatabase.instance);
});

final projectDetailRemoteRepoProvider =
    Provider<ProjectDetailRemoteRepository>((ref) {
  return ProjectDetailRemoteRepository(ref.watch(dioProvider));
});

// ── Estado ───────────────────────────────────────────────────────────────────

class ProjectDetailState {
  const ProjectDetailState({
    this.project,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.evalError,
    this.evalSuccess = false,
    this.fromCache = false,
    this.isSyncing = false,
    this.evalQueueStatus = EvalQueueStatus.none,
    this.evalQueueError,
  });

  final ProjectDetailReadModel? project;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? evalError;
  final bool evalSuccess;

  /// true si los datos provienen del caché local (sin confirmación de red).
  final bool fromCache;

  /// true mientras el background sync está en curso.
  final bool isSyncing;

  /// Estado actual de la evaluación en la cola de salida.
  /// La UI usa esto para mostrar el indicador visual correcto.
  final EvalQueueStatus evalQueueStatus;

  /// Mensaje de error cuando [evalQueueStatus] == [EvalQueueStatus.failed].
  final String? evalQueueError;

  ProjectDetailState copyWith({
    ProjectDetailReadModel? project,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? evalError,
    bool? evalSuccess,
    bool? fromCache,
    bool? isSyncing,
    EvalQueueStatus? evalQueueStatus,
    String? evalQueueError,
  }) =>
      ProjectDetailState(
        project: project ?? this.project,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
        evalError: evalError,
        evalSuccess: evalSuccess ?? this.evalSuccess,
        fromCache: fromCache ?? this.fromCache,
        isSyncing: isSyncing ?? this.isSyncing,
        evalQueueStatus: evalQueueStatus ?? this.evalQueueStatus,
        evalQueueError: evalQueueError ?? this.evalQueueError,
      );
}

/// Estado de la evaluación en la cola de salida.
enum EvalQueueStatus {
  /// Sin evaluación pendiente.
  none,

  /// Evaluación guardada localmente, esperando conexión. Mostrar 🕐.
  pending,

  /// El SyncWorker está enviando ahora mismo. Mostrar ↻ animado.
  syncing,

  /// Fallo después de 3 reintentos. Mostrar ⚠️ con botón "Reintentar".
  failed,
}

// ── Provider ─────────────────────────────────────────────────────────────────

final projectDetailProvider =
    NotifierProviderFamily<ProjectDetailNotifier, ProjectDetailState, String>(
        ProjectDetailNotifier.new);

class ProjectDetailNotifier
    extends FamilyNotifier<ProjectDetailState, String> {
  StreamSubscription<ProjectDetailReadModel?>? _localSub;
  StreamSubscription? _outboxEventSub;

  @override
  ProjectDetailState build(String projectId) {
    ref.onDispose(() {
      _localSub?.cancel();
      _outboxEventSub?.cancel();
    });
    _initialize(projectId);
    return const ProjectDetailState(isLoading: true);
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  ProjectDetailLocalRepository get _localRepo =>
      ref.read(projectDetailLocalRepoProvider);
  ProjectDetailRemoteRepository get _remoteRepo =>
      ref.read(projectDetailRemoteRepoProvider);
  SyncWorker get _syncWorker => ref.read(syncWorkerProvider);
  bool get _isOnline => ref.read(isOnlineProvider);

  String? get _currentUserId {
    final auth = ref.read(authStateProvider);
    return auth is AuthAuthenticated ? auth.uid : null;
  }

  void _initialize(String id) {
    _localSub = _localRepo
        .watch(id, currentUserId: _currentUserId)
        .listen(_onLocalData);
    _syncIfStale(id);

    // Suscribirse a eventos del SyncWorker para actualizar el estado de la cola
    _outboxEventSub = _syncWorker.outboxEvents
        .where((e) => e.projectId == id)
        .listen(_onOutboxEvent);

    // Verificar si ya hay un item en cola al entrar a la pantalla
    _checkInitialQueueStatus(id);
  }

  /// Se ejecuta tanto para el snapshot inicial como para updates futuros del stream.
  void _onLocalData(ProjectDetailReadModel? model) {
    if (model != null) {
      state = state.copyWith(
        project: model,
        isLoading: false,
        error: null,
      );
    } else if (!state.isSyncing) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Recibe notificaciones del SyncWorker sobre cambios en la cola.
  void _onOutboxEvent(({String projectId, OutboxStatus status, OutboxStatus? newStatus}) event) {
    if (event.newStatus == null) {
      // null = éxito, la cola quedó vacía
      state = state.copyWith(
        evalQueueStatus: EvalQueueStatus.none,
        evalSuccess: true,
      );
    } else if (event.newStatus == OutboxStatus.failed) {
      state = state.copyWith(
        evalQueueStatus: EvalQueueStatus.failed,
        evalQueueError: 'Error al enviar. Toca aquí para reintentar.',
      );
    }
  }

  /// Verifica el estado inicial de la cola al montar la pantalla.
  void _checkInitialQueueStatus(String id) {
    ref.read(outboxQueueRepoProvider).getPendingForProject(id).then((pending) {
      if (pending != null) {
        state = state.copyWith(evalQueueStatus: EvalQueueStatus.pending);
      } else {
        ref.read(outboxQueueRepoProvider).getFailedForProject(id).then((failed) {
          if (failed != null) {
            state = state.copyWith(
              evalQueueStatus: EvalQueueStatus.failed,
              evalQueueError: failed.lastError,
            );
          }
        });
      }
    });
  }

  /// Sincroniza desde la red solo si el caché está stale o vacío.
  void _syncIfStale(String id) {
    _localRepo.getFetchedAt(id).then((fetchedAt) {
      final needsSync =
          fetchedAt == null || isCacheStale(fetchedAt, kDetailCacheMaxAge);
      if (needsSync) _syncFromRemote(id);
    });
  }

  /// Fetch remoto → persiste en SQLite → el stream emite → UI se actualiza.
  Future<void> _syncFromRemote(String id) async {
    if (!_isOnline) {
      final hasLocal = await _localRepo.hasData(id);
      if (!hasLocal) {
        state = state.copyWith(
          isLoading: false,
          fromCache: false,
          error: 'Sin conexión y sin datos guardados.',
        );
      } else {
        state = state.copyWith(fromCache: true, isSyncing: false);
      }
      return;
    }

    state = state.copyWith(isSyncing: true);
    try {
      final json = await _remoteRepo.fetchDetail(id);
      await _localRepo.saveDetail(id, json);
      state = state.copyWith(isSyncing: false, fromCache: false);
    } catch (_) {
      final hasLocal = await _localRepo.hasData(id);
      state = state.copyWith(
        isSyncing: false,
        fromCache: hasLocal,
        isLoading: false,
        error: hasLocal ? null : 'Error al cargar el proyecto.',
      );
    }
  }

  // ── Acciones públicas ─────────────────────────────────────────────────────

  /// Fuerza una recarga completa desde la red (pull-to-refresh).
  Future<void> reload() => _syncFromRemote(arg);

  /// RF-04: Envío de evaluación con Optimistic UI + Outbox Pattern.
  ///
  /// Flujo Offline: encola en SQLite, aplica modelo provisional, retorna éxito.
  /// Flujo Online:  envía directo a la API, nótifica al stream.
  Future<void> submitEvaluation(SubmitEvaluationCommand cmd) async {
    final auth = ref.read(authStateProvider);
    if (auth is! AuthAuthenticated) {
      state = state.copyWith(evalError: 'Debes iniciar sesión para evaluar.');
      return;
    }
    if (state.project == null) return;

    final tipo = auth.isTeacher ? 'oficial' : 'sugerencia';
    final criteriaMapList = cmd.criteria.map((c) => c.toMap()).toList();

    state = state.copyWith(
      isSubmitting: true,
      evalError: null,
      evalSuccess: false,
    );

    if (!_isOnline) {
      // ── MODO OFFLINE: Optimistic Update + Enqueue ─────────────────────────

      // 1. Aplicar modelo provisional en memoria (con isOptimistic = true)
      _applyOptimisticEvaluation(
        cmd: cmd,
        auth: auth,
        tipo: tipo,
      );

      // 2. Persistir la evaluación optimista en SQLite para sobrevivir reinicios
      await _persistOptimisticToCache(
        cmd: cmd,
        auth: auth,
        tipo: tipo,
      );

      // 3. Encolar en outbox_queue para que el SyncWorker la envíe
      final outboxItem = buildSubmitEvaluationOutboxItem(
        projectId: cmd.projectId,
        docenteId: auth.uid,
        docenteNombre: auth.displayName,
        tipo: tipo,
        status: cmd.status.name,
        weightedTotalScore: cmd.weightedTotalScore,
        criteria: criteriaMapList,
        generalFeedback: cmd.generalFeedback,
      );
      await _syncWorker.enqueueEvaluation(outboxItem);

      // 4. Informar al usuario que se guardó (no es un error)
      state = state.copyWith(
        isSubmitting: false,
        evalSuccess: true,
        evalQueueStatus: EvalQueueStatus.pending,
      );
      return;
    }

    // ── MODO ONLINE: envío directo a la API ───────────────────────────────
    try {
      await _remoteRepo.submitEvaluation(
        projectId: cmd.projectId,
        docenteId: auth.uid,
        docenteNombre: auth.displayName,
        tipo: tipo,
        status: cmd.status.name,
        weightedTotalScore: cmd.weightedTotalScore,
        criteria: criteriaMapList,
        generalFeedback: cmd.generalFeedback,
      );
      final updatedJson = await _remoteRepo.fetchDetail(cmd.projectId);
      await _localRepo.saveDetail(cmd.projectId, updatedJson);
      state = state.copyWith(
        isSubmitting: false,
        evalSuccess: true,
        fromCache: false,
        evalQueueStatus: EvalQueueStatus.none,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        evalError: e is AppException ? e.message : e.toString(),
      );
    }
  }

  /// Construye y aplica un [EvaluationReadModel] provisional al estado
  /// en memoria sin tocar la red. El modelo tiene [isOptimistic] = true.
  void _applyOptimisticEvaluation({
    required SubmitEvaluationCommand cmd,
    required AuthAuthenticated auth,
    required String tipo,
  }) {
    final optimistic = EvaluationReadModel(
      id: 'optimistic_${cmd.projectId}',
      evaluatorId: auth.uid,
      evaluatorName: auth.displayName,
      criteria: cmd.criteria,
      weightedTotalScore: cmd.weightedTotalScore,
      status: cmd.status,
      esPublico: false,
      tipo: tipo,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    final project = state.project;
    if (project == null) return;

    // Reemplazar la eval del usuario actual (si existe) con la provisional
    final otherEvals = project.evaluations
        .where((e) => e.evaluatorId != auth.uid)
        .toList();

    state = state.copyWith(
      project: ProjectDetailReadModel(
        id: project.id,
        title: project.title,
        description: project.description,
        category: project.category,
        year: project.year,
        teamName: project.teamName,
        teamMembers: project.teamMembers,
        avgScore: project.avgScore,
        totalVotes: project.totalVotes,
        status: project.status,
        techStack: project.techStack,
        coverImageUrl: project.coverImageUrl,
        videoUrl: project.videoUrl,
        myEvaluation: optimistic,
        evaluations: [...otherEvals, optimistic],
        images: project.images,
      ),
    );
  }

  /// Persiste el modelo optimista en SQLite para que sobreviva reinicios.
  Future<void> _persistOptimisticToCache({
    required SubmitEvaluationCommand cmd,
    required AuthAuthenticated auth,
    required String tipo,
  }) async {
    final cached = await _localRepo.getFetchedAt(cmd.projectId);
    if (cached == null) return; // Sin caché base, no hay nada que enriquecer

    final db = await _localRepo.getRawData(cmd.projectId);
    if (db == null) return;

    final optimisticEval = {
      'id': 'optimistic_${cmd.projectId}',
      'docenteId': auth.uid,
      'docenteNombre': auth.displayName,
      'tipo': tipo,
      'status': cmd.status.name,
      'weightedTotalScore': cmd.weightedTotalScore,
      'criteria': cmd.criteria.map((c) => c.toMap()).toList(),
      'esPublico': false,
      'createdAt': DateTime.now().toIso8601String(),
      '_isOptimistic': true,
    };

    final evals = List<dynamic>.from(db['evaluations'] as List? ?? []);
    evals.removeWhere((e) => (e as Map)['docenteId'] == auth.uid);
    evals.add(optimisticEval);

    final updated = Map<String, dynamic>.from(db)..['evaluations'] = evals;
    await _localRepo.saveDetail(cmd.projectId, updated);
  }

  /// Fuerza el reintento de una evaluación marcada como `failed`.
  Future<void> retryFailedEvaluation() async {
    state = state.copyWith(
      evalQueueStatus: EvalQueueStatus.syncing,
      evalQueueError: null,
    );
    await _syncWorker.retryFailed(arg);
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
      await _remoteRepo.toggleVisibility(
        evalId: evalId,
        userId: auth.uid,
        esPublico: esPublico,
      );
      final updatedJson = await _remoteRepo.fetchDetail(arg);
      await _localRepo.saveDetail(arg, updatedJson);
    } catch (e) {
      state = state.copyWith(
        evalError: e is AppException ? e.message : e.toString(),
      );
    }
  }
}
