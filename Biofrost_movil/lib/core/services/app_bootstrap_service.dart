// core/services/app_bootstrap_service.dart
//
// Servicio de pre-carga que se ejecuta tras un login exitoso.
// Pobla SQLite con la primera página del showcase para que la UI tenga datos
// inmediatamente en el próximo arrange, incluso si el usuario está offline.
//
// REGLA: Solo hace fetch de la lista de proyectos (primera página).
//        Los detalles se cachean ON-DEMAND la primera vez que el usuario los visita.
//        Pre-cargar todos los detalles sería demasiado costoso en red y batería.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../features/showcase/data/repositories/showcase_local_repository.dart';
import '../../features/showcase/data/repositories/showcase_remote_repository.dart';
import '../cache/cache_database.dart';
import '../cache/cache_policy.dart';
import 'api_service.dart';

final _logger = Logger();

final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  return AppBootstrapService(
    localRepo: ShowcaseLocalRepository(CacheDatabase.instance),
    remoteRepo: ShowcaseRemoteRepository(ref.watch(dioProvider)),
  );
});

class AppBootstrapService {
  AppBootstrapService({
    required this.localRepo,
    required this.remoteRepo,
  });

  final ShowcaseLocalRepository localRepo;
  final ShowcaseRemoteRepository remoteRepo;

  /// Ejecutar tras login exitoso — siempre en background (no awaited desde la UI).
  ///
  /// Estrategia:
  ///   1. Si el caché es fresco (< TTL), no hace nada → ahorra datos.
  ///   2. Si el caché está stale o vacío, hace fetch y persiste en SQLite.
  ///   3. Los errores de red se tragan silenciosamente — el usuario verá el
  ///      estado de error cuando abra la pantalla Showcase.
  Future<void> run() async {
    try {
      final fetchedAt = await localRepo.getFetchedAt();
      final isFresh = fetchedAt != null &&
          !isCacheStale(fetchedAt, kShowcaseCacheMaxAge);

      if (isFresh) {
        _logger.d('[Bootstrap] Caché de showcase fresco — skip pre-fetch.');
        return;
      }

      _logger.i('[Bootstrap] Pre-cargando primera página del showcase...');
      final raw = await remoteRepo.fetchProjects(limit: 20);
      await localRepo.saveProjects(raw);
      _logger.i('[Bootstrap] Showcase pre-cargado en SQLite ✓');
    } catch (e, st) {
      // El bootstrap fallido no es crítico — la app funciona sin él.
      _logger.w('[Bootstrap] Pre-fetch falló (no crítico)', error: e, stackTrace: st);
    }
  }
}
