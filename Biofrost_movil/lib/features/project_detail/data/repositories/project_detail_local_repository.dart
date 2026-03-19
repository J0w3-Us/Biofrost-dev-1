// features/project_detail/data/repositories/project_detail_local_repository.dart
//
// RESPONSABILIDAD ÚNICA: Leer y escribir el detalle de proyectos en SQLite.
// Nunca toca Dio. Nunca conoce la red.
// La UI y los Notifiers siempre leen de aquí — jamás directamente de la API.

import '../../../../core/cache/cache_database.dart';
import '../../domain/models/project_detail_read_model.dart';

class ProjectDetailLocalRepository {
  ProjectDetailLocalRepository(this._db);
  final CacheDatabase _db;

  // ── Lectura reactiva ────────────────────────────────────────────────────

  /// Emite el modelo cada vez que [saveDetail] escribe en SQLite.
  /// Emite null si todavía no hay datos para este [id].
  ///
  /// El Notifier se suscribe aquí en su [build]. La UI nunca espera:
  /// si hay caché → ve datos inmediatamente; si no → ve loading hasta el fetch.
  Stream<ProjectDetailReadModel?> watch(
    String id, {
    String? currentUserId,
  }) async* {
    // 1. Emitir el snapshot inicial desde SQLite (puede ser null)
    final snapshot = await _db.getDetail(id);
    if (snapshot != null) {
      yield ProjectDetailReadModel.fromJson(
        snapshot.data,
        currentUserId: currentUserId,
      );
    } else {
      yield null;
    }

    // 2. Emitir futuros cambios cuando upsertDetail escriba
    yield* _db.watchDetail(id).map(
          (json) => ProjectDetailReadModel.fromJson(
            json,
            currentUserId: currentUserId,
          ),
        );
  }

  // ── Escritura ───────────────────────────────────────────────────────────

  /// Persiste el JSON crudo del backend en SQLite.
  /// Después de esta llamada, [watch] emitirá el nuevo valor automáticamente.
  Future<void> saveDetail(String id, Map<String, dynamic> json) =>
      _db.upsertDetail(id, json);

  // ── Consultas puntuales ─────────────────────────────────────────────────

  /// Retorna el timestamp (ms epoch) del último fetch, o null si no hay caché.
  /// Los Notifiers usan esto para decidir si el caché está stale.
  Future<int?> getFetchedAt(String id) async {
    final snapshot = await _db.getDetail(id);
    return snapshot?.fetchedAt;
  }

  /// Retorna true si ya existe algún dato local para este [id].
  Future<bool> hasData(String id) async {
    final snapshot = await _db.getDetail(id);
    return snapshot != null;
  }

  /// Retorna el JSON crudo almacenado en SQLite sin deserializar al modelo.
  /// Usado por el Notifier para enriquecer el caché con evaluaciones optimistas.
  Future<Map<String, dynamic>?> getRawData(String id) async {
    final snapshot = await _db.getDetail(id);
    return snapshot?.data;
  }
}
