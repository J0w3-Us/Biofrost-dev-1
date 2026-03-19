// core/sync/sync_worker.dart
// El Worker que escucha la reconexión a internet y procesa la cola FIFO.
//
// Ciclo de vida:
//   App inicia → SyncWorker.init() → si hay pending → processCola()
//   connectivity: false → no hacer nada
//   connectivity: true  → processCola()
//
// Procesamiento SECUENCIAL (un item a la vez):
//   UPDATE status = 'processing'
//   RemoteRepository.submitEvaluation()
//   Éxito → DELETE + LocalRepo.refreshDetail()
//   Fallo  → attempts++, backoff, max 3 intentos → status = 'failed'

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../cache/cache_database.dart';
import '../providers/connectivity_provider.dart';
import '../services/api_service.dart';
import '../../features/project_detail/data/repositories/project_detail_local_repository.dart';
import '../../features/project_detail/data/repositories/project_detail_remote_repository.dart';
import 'outbox_item.dart';
import 'outbox_queue_repository.dart';

// ── Constantes ───────────────────────────────────────────────────────────────

/// Número máximo de reintentos antes de marcar un item como `failed`.
const _maxAttempts = 3;

/// Backoff progresivo entre reintentos.
const _backoffDurations = [
  Duration.zero,           // Intento 1: inmediato
  Duration(seconds: 30),   // Intento 2: 30s
  Duration(minutes: 2),    // Intento 3: 2min
];

final _logger = Logger();

// ── Providers ─────────────────────────────────────────────────────────────────

final outboxQueueRepoProvider = Provider<OutboxQueueRepository>((ref) {
  return OutboxQueueRepository(CacheDatabase.instance);
});

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final worker = SyncWorker(
    outboxRepo: ref.watch(outboxQueueRepoProvider),
    remoteRepo: ProjectDetailRemoteRepository(ref.watch(dioProvider)),
    localRepo: ProjectDetailLocalRepository(CacheDatabase.instance),
    ref: ref,
  );
  ref.onDispose(worker.dispose);
  return worker;
});

// ── SyncWorker ────────────────────────────────────────────────────────────────

class SyncWorker {
  SyncWorker({
    required this.outboxRepo,
    required this.remoteRepo,
    required this.localRepo,
    required this.ref,
  });

  final OutboxQueueRepository outboxRepo;
  final ProjectDetailRemoteRepository remoteRepo;
  final ProjectDetailLocalRepository localRepo;
  final Ref ref;

  StreamSubscription<bool>? _connectivitySub;
  bool _isProcessing = false;

  // ── Inicialización ────────────────────────────────────────────────────────

  /// Llamar una sola vez desde [bootstrap.dart] después de [runApp].
  /// Recupera items `processing` huérfanos y se suscribe a la conectividad.
  Future<void> init() async {
    // Recuperar items que quedaron en `processing` si la app fue killed
    await outboxRepo.resetProcessingToPending();

    // Procesar cola inmediatamente si ya hay conexión
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) {
      _processCola();
    }

    // Escuchar cambios de conectividad
    _connectivitySub = ref
        .read(connectivityProvider.stream)
        .where((online) => online) // Solo cuando vuelve la red
        .listen((_) => _processCola());
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  // ── Procesamiento de la cola ──────────────────────────────────────────────

  /// Procesa la cola FIFO de forma secuencial.
  /// Es idempotente: si ya está procesando, no lanza una segunda instancia.
  Future<void> _processCola() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final items = await outboxRepo.getPending();
      if (items.isEmpty) {
        _logger.d('[SyncWorker] Cola vacía, nada que sincronizar.');
        return;
      }

      _logger.i('[SyncWorker] Procesando ${items.length} item(s) en cola...');

      for (final item in items) {
        await _processItem(item);
      }

      _logger.i('[SyncWorker] Cola procesada.');
    } finally {
      _isProcessing = false;
    }
  }

  /// Intenta enviar un item al backend con backoff exponencial.
  Future<void> _processItem(OutboxItem item) async {
    // Esperar backoff según el número de intentos previos
    final backoffIndex = item.attempts.clamp(0, _backoffDurations.length - 1);
    final backoff = _backoffDurations[backoffIndex];
    if (backoff > Duration.zero) {
      _logger.d('[SyncWorker] Backoff ${backoff.inSeconds}s para item ${item.id}');
      await Future.delayed(backoff);
    }

    // Marcar como `processing`
    await outboxRepo.updateStatus(item.id, status: OutboxStatus.processing);

    try {
      await _dispatch(item);

      // ✅ Éxito: eliminar de la cola y refrescar el caché del proyecto
      await outboxRepo.dequeue(item.id);
      _logger.i('[SyncWorker] ✅ Item ${item.id} sincronizado.');

      // Refrescar el detalle del proyecto en SQLite para quitar el optimistic
      await _refreshProjectDetail(item.projectId);

      // Notificar al ProjectDetailNotifier de este proyecto
      _notifySuccess(item);
    } catch (e) {
      final newAttempts = item.attempts + 1;
      _logger.w('[SyncWorker] ⚠️ Fallo en item ${item.id} '
          '(intento $newAttempts/$_maxAttempts): $e');

      if (newAttempts >= _maxAttempts) {
        // Marcar como fallido permanentemente
        await outboxRepo.updateStatus(
          item.id,
          status: OutboxStatus.failed,
          attempts: newAttempts,
          lastError: e.toString(),
        );
        _logger.e('[SyncWorker] ❌ Item ${item.id} marcado como FAILED.');
        _notifyFailure(item, e.toString());
      } else {
        // Devolver a `pending` para el próximo intento
        await outboxRepo.updateStatus(
          item.id,
          status: OutboxStatus.pending,
          attempts: newAttempts,
          lastError: e.toString(),
        );
      }
    }
  }

  /// Despacha la operación correcta según [item.operation].
  Future<void> _dispatch(OutboxItem item) async {
    switch (item.operation) {
      case 'submit_evaluation':
        await _submitEvaluation(item);
      case 'toggle_visibility':
        await _toggleVisibility(item);
      default:
        throw UnsupportedError('Operación desconocida: ${item.operation}');
    }
  }

  Future<void> _submitEvaluation(OutboxItem item) async {
    final p = item.payload;
    await remoteRepo.submitEvaluation(
      projectId: p['projectId'] as String,
      docenteId: p['docenteId'] as String,
      docenteNombre: p['docenteNombre'] as String,
      tipo: p['tipo'] as String,
      status: p['status'] as String,
      weightedTotalScore: (p['weightedTotalScore'] as num).toDouble(),
      criteria: (p['criteria'] as List)
          .cast<Map<String, dynamic>>(),
      generalFeedback: p['generalFeedback'] as String?,
    );
  }

  Future<void> _toggleVisibility(OutboxItem item) async {
    final p = item.payload;
    await remoteRepo.toggleVisibility(
      evalId: p['evalId'] as String,
      userId: p['userId'] as String,
      esPublico: p['esPublico'] as bool,
    );
  }

  // ── Comunicación con los Notifiers ────────────────────────────────────────

  /// Refresca el detalle del proyecto en SQLite para que el stream reactivo
  /// emita el dato confirmado por el servidor (sin el flag `_isOptimistic`).
  Future<void> _refreshProjectDetail(String projectId) async {
    try {
      final updatedJson = await remoteRepo.fetchDetail(projectId);
      await localRepo.saveDetail(projectId, updatedJson);
      // El stream reactivo notifica al ProjectDetailNotifier automáticamente.
    } catch (_) {
      // Si falla el refresco, la UI seguirá mostrando el dato optimista.
      // El próximo sync corregirá esto.
    }
  }

  /// Notifica al stream de outbox que un item fue procesado exitosamente.
  /// Los Notifiers pueden escuchar esto para actualizar su estado de cola.
  void _notifySuccess(OutboxItem item) {
    if (!_outboxController.isClosed) {
      _outboxController.add((projectId: item.projectId, status: OutboxStatus.pending, newStatus: null));
    }
  }

  void _notifyFailure(OutboxItem item, String error) {
    if (!_outboxController.isClosed) {
      _outboxController.add((
        projectId: item.projectId,
        status: OutboxStatus.failed,
        newStatus: OutboxStatus.failed,
      ));
    }
  }

  // ── Stream de eventos de outbox (para los Notifiers) ─────────────────────

  final _outboxController =
      StreamController<({String projectId, OutboxStatus status, OutboxStatus? newStatus})>.broadcast();

  /// Emite un evento cada vez que el estado de la cola para un proyecto cambia.
  Stream<({String projectId, OutboxStatus status, OutboxStatus? newStatus})>
      get outboxEvents => _outboxController.stream;

  // ── API pública para los Notifiers ────────────────────────────────────────

  /// Encola una evaluación offline y dispara el proceso inmediatamente
  /// si hay conexión (para el happy path de red momentáneamente caída).
  Future<void> enqueueEvaluation(OutboxItem item) async {
    await outboxRepo.enqueue(item);
    _logger.i('[SyncWorker] 📬 Item encolado: ${item.id}');

    final isOnline = ref.read(isOnlineProvider);
    if (isOnline && !_isProcessing) {
      // Hay red: intentar procesar de inmediato (caso de fallo temporal rápido)
      _processCola();
    }
  }

  /// Fuerza el reintento de un item específico en estado `failed`.
  Future<void> retryFailed(String projectId) async {
    final failed = await outboxRepo.getFailedForProject(projectId);
    if (failed == null) return;

    await outboxRepo.updateStatus(
      failed.id,
      status: OutboxStatus.pending,
      attempts: 0, // Resetear intentos para darle una oportunidad limpia
      lastError: null,
    );

    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) _processCola();
  }
}

// ── Factory para crear OutboxItems ────────────────────────────────────────────

/// Crea un [OutboxItem] para una operación `submit_evaluation`.
OutboxItem buildSubmitEvaluationOutboxItem({
  required String projectId,
  required String docenteId,
  required String docenteNombre,
  required String tipo,
  required String status,
  required double weightedTotalScore,
  required List<Map<String, dynamic>> criteria,
  String? generalFeedback,
}) {
  return OutboxItem(
    id: const Uuid().v4(),
    operation: 'submit_evaluation',
    payload: {
      'projectId': projectId,
      'docenteId': docenteId,
      'docenteNombre': docenteNombre,
      'tipo': tipo,
      'status': status,
      'weightedTotalScore': weightedTotalScore,
      'criteria': criteria,
      if (generalFeedback != null) 'generalFeedback': generalFeedback,
    },
    projectId: projectId,
    status: OutboxStatus.pending,
    createdAt: DateTime.now().millisecondsSinceEpoch,
    attempts: 0,
  );
}
