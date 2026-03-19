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
  static const String publicProjects = '/api/projects/public';
  static String projectById(String id) => '/api/projects/$id';
  static String teacherProjects(String teacherId) =>
      '/api/projects/teacher/$teacherId';
  static String projectMembers(String projectId) =>
      '/api/projects/$projectId/members';

  // ── Evaluations ───────────────────────────────────────────────────────────
  static const String evaluations = '/api/evaluations';
  static String evaluationsByProject(String projectId) =>
      '/api/evaluations/project/$projectId';
  static String evaluationVisibility(String evalId) =>
      '/api/evaluations/$evalId/visibility';

  // ── Ranking ───────────────────────────────────────────────────────────────
  static const String ranking = '/api/ranking';

  // ── Profile ──────────────────────────────────────────────────────────────
  static const String profile = '/api/users/me';
  static String userById(String id) => '/api/users/$id';
  static String userPublicProfile(String id) => '/api/users/$id/profile';
  static String userPhoto(String id) => '/api/users/$id/photo';
  static String userSocialLinks(String id) => '/api/users/$id/social';
  static String userDisplayName(String id) => '/api/users/$id/display-name';
  static String userSoftDelete(String id) => '/api/users/$id/soft-delete';

  // ── Admin — Catálogos (para registro docente) ─────────────────────────
  static const String adminCarreras = '/api/admin/carreras';
  static const String adminMaterias = '/api/admin/materias';
  static const String adminGroups = '/api/admin/groups';
  static String adminGroupById(String id) => '/api/admin/groups/$id';

  // ── Storage ───────────────────────────────────────────────────────────────
  static const String storageUpload = '/api/storage/upload';

  // ── Audit Logs ───────────────────────────────────────────────────────────
  static const String auditLogs = '/api/audit-logs';
  static String auditLogById(String id) => '/api/audit-logs/$id';
}
