// features/project_detail/data/datasources/project_detail_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/commands/submit_evaluation_command.dart';
import '../../domain/models/project_detail_read_model.dart';

class ProjectDetailRemoteDatasource {
  ProjectDetailRemoteDatasource(this._dio);
  final Dio _dio;

  /// RF-03: Obtiene detalle de un proyecto
  Future<ProjectDetailReadModel> getProjectDetail(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.projectById(id));
      return ProjectDetailReadModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// RF-04: Envia evaluacion (UPSERT en backend)
  Future<void> submitEvaluation(SubmitEvaluationCommand cmd) async {
    try {
      await _dio.post(
        ApiEndpoints.evaluations,
        data: {
          'projectId': cmd.projectId,
          'stars': cmd.stars,
          if (cmd.feedback != null && cmd.feedback!.isNotEmpty)
            'feedback': cmd.feedback,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
