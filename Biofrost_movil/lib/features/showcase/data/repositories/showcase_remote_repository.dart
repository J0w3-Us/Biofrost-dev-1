// features/showcase/data/repositories/showcase_remote_repository.dart
//
// RESPONSABILIDAD ÚNICA: Hacer fetch de la lista de proyectos vía Dio.
// Nunca escribe en SQLite. Devuelve el response crudo para que el Notifier lo persista.

import 'package:dio/dio.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_service.dart';

class ShowcaseRemoteRepository {
  ShowcaseRemoteRepository(this._dio);
  final Dio _dio;

  /// Obtiene la lista de proyectos públicos con filtros opcionales.
  ///
  /// Devuelve el [data] crudo del response (puede ser List o Map paginado).
  /// El Notifier es quien decide cómo persistirlo en SQLite.
  ///
  /// Lanza [AppException] ante cualquier fallo de red.
  Future<dynamic> fetchProjects({
    String? cursor,
    String? search,
    String? category,
    int? year,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.publicProjects,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null) 'category': category,
          if (year != null) 'year': year,
          'limit': limit,
        },
      );
      return res.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
