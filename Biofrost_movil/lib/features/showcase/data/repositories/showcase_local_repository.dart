// features/showcase/data/repositories/showcase_local_repository.dart
//
// RESPONSABILIDAD ÚNICA: Leer y escribir la lista de proyectos en SQLite.
// Nunca toca Dio. Es la Única Fuente de Verdad para ShowcaseNotifier.

import 'dart:convert';

import '../../../../core/cache/cache_database.dart';
import '../../domain/models/project_read_model.dart';

/// Clave canónica para la página inicial del showcase.
const kShowcasePageKey = 'showcase_initial';

class ShowcaseLocalRepository {
  ShowcaseLocalRepository(this._db);
  final CacheDatabase _db;

  // ── Lectura reactiva ────────────────────────────────────────────────────

  /// Emite la lista de proyectos cada vez que [saveProjects] escribe en SQLite.
  /// Emite una lista vacía [] si todavía no hay datos.
  ///
  /// El ShowcaseNotifier se suscribe aquí en su [build].
  Stream<List<ProjectReadModel>> watch() async* {
    // 1. Emitir snapshot inicial
    final snapshot = await _db.getProjects(kShowcasePageKey);
    if (snapshot != null) {
      yield _parse(snapshot.data);
    } else {
      yield [];
    }

    // 2. Emitir cambios futuros
    yield* _db.watchProjects(kShowcasePageKey).map(_parse);
  }

  // ── Escritura ───────────────────────────────────────────────────────────

  /// Guarda el resultado crudo del API (puede ser List o Map paginado) en SQLite.
  /// Después de esta llamada, [watch] emitirá la nueva lista automáticamente.
  Future<void> saveProjects(dynamic rawApiResponse) async {
    // Normalizar a un Map envolvente para que SQLite siempre guarde un Map.
    final Map<String, dynamic> envelope;
    if (rawApiResponse is List) {
      envelope = {'items': rawApiResponse, 'paginado': false};
    } else if (rawApiResponse is Map<String, dynamic>) {
      envelope = rawApiResponse;
    } else {
      // No hacer nada si el dato es inválido
      return;
    }
    await _db.upsertProjects(kShowcasePageKey, envelope);
  }

  // ── Consultas puntuales ─────────────────────────────────────────────────

  /// Retorna el timestamp del último fetch, o null si no hay caché.
  Future<int?> getFetchedAt() async {
    final snapshot = await _db.getProjects(kShowcasePageKey);
    return snapshot?.fetchedAt;
  }

  /// Retorna true si hay datos locales guardados.
  Future<bool> hasData() async {
    final snapshot = await _db.getProjects(kShowcasePageKey);
    return snapshot != null;
  }

  // ── Helpers privados ────────────────────────────────────────────────────

  /// Deserializa el JSON del envelope al modelo de dominio.
  List<ProjectReadModel> _parse(Map<String, dynamic> envelope) {
    final dynamic rawItems = envelope['items'] ?? envelope;
    final List<dynamic> rawList =
        rawItems is List ? rawItems : jsonDecode(jsonEncode(rawItems)) as List;

    final result = <ProjectReadModel>[];
    for (final e in rawList) {
      try {
        result.add(ProjectReadModel.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Ignora proyectos con datos corruptos
      }
    }
    return result;
  }
}
