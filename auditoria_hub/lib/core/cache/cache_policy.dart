// core/cache/cache_policy.dart — Reglas de expiración para el caché local

/// Tiempo máximo de vida para la lista de proyectos (showcase)
const kShowcaseCacheMaxAge = Duration(minutes: 15);

/// Tiempo máximo de vida para el detalle de un proyecto
const kDetailCacheMaxAge = Duration(minutes: 30);

/// Devuelve true si los datos almacenados ya superaron su tiempo de vida.
/// [fetchedAtMs] — timestamp en milisegundos (epoch) del momento del fetch.
bool isCacheStale(int fetchedAtMs, Duration maxAge) {
  final fetchedAt = DateTime.fromMillisecondsSinceEpoch(fetchedAtMs);
  return DateTime.now().difference(fetchedAt) > maxAge;
}
