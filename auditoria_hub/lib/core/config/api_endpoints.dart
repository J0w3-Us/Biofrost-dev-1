// core/config/api_endpoints.dart — Endpoints de la API
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  // ── Projects ─────────────────────────────────────────────────────────────
  static const String projects = '/api/projects';
  static String projectById(String id) => '/api/projects/$id';

  // ── Evaluations ───────────────────────────────────────────────────────────
  static const String evaluations = '/api/evaluations';
  static String evaluationsByProject(String projectId) =>
      '/api/evaluations/project/$projectId';

  // ── Ranking ───────────────────────────────────────────────────────────────
  static const String ranking = '/api/ranking';

  // ── Profile ──────────────────────────────────────────────────────────────
  static const String profile = '/api/users/me';
  static String userById(String id) => '/api/users/$id';

  // ── Audit Logs ───────────────────────────────────────────────────────────
  static const String auditLogs = '/api/audit-logs';
  static String auditLogById(String id) => '/api/audit-logs/$id';
}
