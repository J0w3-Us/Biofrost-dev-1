// features/showcase/data/datasources/showcase_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/models/project_read_model.dart';

class ShowcaseRemoteDatasource {
  ShowcaseRemoteDatasource(this._dio);
  final Dio _dio;

  /// RF-02: Obtiene proyectos paginados con filtros opcionales
  Future<ProjectPageResult> getProjects({
    String? cursor,
    String? search,
    String? category,
    int? year,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.projects,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null) 'category': category,
          if (year != null) 'year': year,
          'limit': limit,
        },
      );
      return ProjectPageResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
