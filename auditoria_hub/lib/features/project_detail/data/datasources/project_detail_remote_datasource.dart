// features/project_detail/data/datasources/project_detail_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../core/cache/cache_database.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/models/project_detail_read_model.dart';

class ProjectDetailRemoteDatasource {
  ProjectDetailRemoteDatasource(this._dio);
  final Dio _dio;

  final _cache = CacheDatabase.instance;

  /// RF-03: Obtiene detalle de un proyecto — estrategia cache-first.
  ///
  /// Hace fetch paralelo de GET /api/projects/{id} y
  /// GET /api/evaluations/project/{id}, combina ambos en el modelo.
  /// [currentUserId] se usa para determinar la evaluación propia del usuario.
  Future<ProjectDetailReadModel> getProjectDetail(
    String id, {
    bool isOnline = true,
    String? currentUserId,
  }) async {
    if (!isOnline) {
      final cached = await _cache.getDetail(id);
      if (cached == null) throw const NetworkException();
      return ProjectDetailReadModel.fromJson(
        cached.data,
        currentUserId: currentUserId,
      );
    }

    try {
      // Fetch paralelo: detalle + evaluaciones
      final responses = await Future.wait([
        _dio.get(ApiEndpoints.projectById(id)),
        _dio.get(ApiEndpoints.evaluationsByProject(id)),
      ]);
      final detailJson =
          Map<String, dynamic>.from(responses[0].data as Map<String, dynamic>);
      detailJson['evaluations'] = responses[1].data as List? ?? [];

      await _cache.upsertDetail(id, detailJson);
      return ProjectDetailReadModel.fromJson(
        detailJson,
        currentUserId: currentUserId,
      );
    } on DioException catch (e) {
      final cached = await _cache.getDetail(id);
      if (cached != null) {
        return ProjectDetailReadModel.fromJson(
          cached.data,
          currentUserId: currentUserId,
        );
      }
      throw handleDioError(e);
    }
  }

  /// RF-04: Envía evaluación al backend — requiere conexión.
  ///
  /// Body esperado por POST /api/evaluations:
  /// {
  ///   projectId,
  ///   docenteId,
  ///   docenteNombre,
  ///   tipo,
  ///   status,
  ///   weightedTotalScore,
  ///   criteria,
  ///   calificacion
  /// }
  Future<void> submitEvaluation({
    required String projectId,
    required String docenteId,
    required String docenteNombre,
    required String tipo,
    required String status,
    required double weightedTotalScore,
    required List<Map<String, dynamic>> criteria,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.evaluations,
        data: {
          'projectId': projectId,
          'docenteId': docenteId,
          'docenteNombre': docenteNombre,
          'tipo': tipo,
          'status': status,
          'weightedTotalScore': weightedTotalScore,
          'criteria': criteria,
          // Compatibilidad API legado en escala 0-100.
          if (tipo == 'oficial')
            'calificacion': weightedTotalScore.round().clamp(0, 100),
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Cambia la visibilidad (público/privado) de una evaluación.
  Future<void> toggleVisibility({
    required String evalId,
    required String userId,
    required bool esPublico,
  }) async {
    try {
      await _dio.patch(
        ApiEndpoints.evaluationVisibility(evalId),
        data: {'userId': userId, 'esPublico': esPublico},
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
