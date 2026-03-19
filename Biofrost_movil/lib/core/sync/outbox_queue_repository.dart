// core/sync/outbox_queue_repository.dart
// RESPONSABILIDAD ÚNICA: CRUD de la tabla outbox_queue en SQLite.
// El SyncWorker y el ProjectDetailNotifier dependen de esta clase.
// Nunca toca Dio. Nunca decide cuándo sincronizar.

import 'package:sqflite/sqflite.dart';

import '../cache/cache_database.dart';
import 'outbox_item.dart';

class OutboxQueueRepository {
  OutboxQueueRepository(this._db);
  final CacheDatabase _db;

  // ── Escritura ────────────────────────────────────────────────────────────

  /// Inserta o reemplaza un item en la cola.
  ///
  /// Regla de negocio: un proyecto solo puede tener UNA evaluación pendiente.
  /// Si ya existe un item `pending` para el mismo [projectId], se reemplaza
  /// con el nuevo payload (el docente corrigió su evaluación offline).
  Future<void> enqueue(OutboxItem item) async {
    final db = await _db.database;

    // Eliminar el item pendiente anterior para el mismo proyecto (si existe)
    await db.delete(
      'outbox_queue',
      where: 'project_id = ? AND status = ?',
      whereArgs: [item.projectId, OutboxStatus.pending.name],
    );

    await db.insert(
      'outbox_queue',
      item.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Elimina un item de la cola (tras sincronización exitosa).
  Future<void> dequeue(String id) async {
    final db = await _db.database;
    await db.delete('outbox_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Actualiza el estado de un item en la cola.
  Future<void> updateStatus(
    String id, {
    required OutboxStatus status,
    int? attempts,
    String? lastError,
  }) async {
    final db = await _db.database;
    final values = <String, dynamic>{'status': status.name};
    if (attempts != null) values['attempts'] = attempts;
    if (lastError != null) values['last_error'] = lastError;
    await db.update('outbox_queue', values, where: 'id = ?', whereArgs: [id]);
  }

  // ── Lectura ──────────────────────────────────────────────────────────────

  /// Devuelve todos los items pendientes o en fallo, ordenados FIFO.
  Future<List<OutboxItem>> getPending() async {
    final db = await _db.database;
    final rows = await db.query(
      'outbox_queue',
      where: 'status IN (?, ?)',
      whereArgs: [OutboxStatus.pending.name, OutboxStatus.processing.name],
      orderBy: 'created_at ASC',
    );
    return rows.map(OutboxItem.fromRow).toList();
  }

  /// Devuelve el item pendiente para un proyecto específico, o null si no existe.
  Future<OutboxItem?> getPendingForProject(String projectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'outbox_queue',
      where: 'project_id = ? AND status IN (?, ?)',
      whereArgs: [
        projectId,
        OutboxStatus.pending.name,
        OutboxStatus.processing.name,
      ],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OutboxItem.fromRow(rows.first);
  }

  /// Devuelve el item `failed` para un proyecto específico, o null si no existe.
  Future<OutboxItem?> getFailedForProject(String projectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'outbox_queue',
      where: 'project_id = ? AND status = ?',
      whereArgs: [projectId, OutboxStatus.failed.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OutboxItem.fromRow(rows.first);
  }

  /// Cuenta cuántos items hay en la cola (pendientes + en proceso).
  Future<int> countPending() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM outbox_queue WHERE status IN (?, ?)',
      [OutboxStatus.pending.name, OutboxStatus.processing.name],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Restablece todos los items `processing` a `pending`.
  /// Se llama al arrancar la app para recuperar items que quedaron a medias.
  Future<void> resetProcessingToPending() async {
    final db = await _db.database;
    await db.update(
      'outbox_queue',
      {'status': OutboxStatus.pending.name},
      where: 'status = ?',
      whereArgs: [OutboxStatus.processing.name],
    );
  }

  /// Limpia toda la cola (al hacer logout).
  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('outbox_queue');
  }
}
