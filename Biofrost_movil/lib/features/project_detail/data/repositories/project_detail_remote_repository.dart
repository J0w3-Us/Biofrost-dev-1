// features/project_detail/data/repositories/project_detail_remote_repository.dart
//
// RESPONSABILIDAD ÚNICA: Hacer fetch a la API REST vía Dio.
// Nunca escribe en SQLite directamente. Nunca decide qué mostrar en la UI.
// Contiene el Patrón Adaptador para el envío de evaluaciones al backend legado.

import 'package:dio/dio.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_service.dart';

class ProjectDetailRemoteRepository {
  ProjectDetailRemoteRepository(this._dio);
  final Dio _dio;

  // ── Lectura ─────────────────────────────────────────────────────────────

  /// Obtiene el detalle combinado de un proyecto (datos + evaluaciones).
  ///
  /// Hace dos requests en paralelo para minimizar latencia:
  ///   GET /api/projects/{id}          → datos del proyecto
  ///   GET /api/evaluations/project/{id} → evaluaciones asociadas
  ///
  /// Devuelve un [Map] listo para ser guardado en SQLite por el Notifier.
  /// Lanza [AppException] ante cualquier fallo de red.
  Future<Map<String, dynamic>> fetchDetail(String id) async {
    try {
      final responses = await Future.wait([
        _dio.get(ApiEndpoints.projectById(id)),
        _dio.get(ApiEndpoints.evaluationsByProject(id)),
      ]);

      final detailJson = Map<String, dynamic>.from(
        responses[0].data as Map<String, dynamic>,
      );

      final evalsData = responses[1].data;
      detailJson['evaluations'] = _parseEvaluations(evalsData);

      return detailJson;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Escritura ────────────────────────────────────────────────────────────

  /// RF-04: Envía una evaluación al backend usando el Patrón Adaptador.
  ///
  /// Transforma el modelo rico de rúbricas (N criterios con pesos y scores)
  /// al contrato simplificado de la API legada:
  ///   POST /api/evaluations → { projectId, docenteId, docenteNombre,
  ///                             tipo, contenido (String), calificacion (int) }
  Future<void> submitEvaluation({
    required String projectId,
    required String docenteId,
    required String docenteNombre,
    required String tipo,
    required String status,
    required double weightedTotalScore,
    required List<Map<String, dynamic>> criteria,
    String? generalFeedback,
  }) async {
    try {
      final payload = _buildLegacyPayload(
        projectId: projectId,
        docenteId: docenteId,
        docenteNombre: docenteNombre,
        tipo: tipo,
        criteria: criteria,
        weightedTotalScore: weightedTotalScore,
        generalFeedback: generalFeedback,
      );
      await _dio.post(ApiEndpoints.evaluations, data: payload);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// Cambia la visibilidad pública/privada de una evaluación.
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

  // ── Adaptador: métodos privados ─────────────────────────────────────────

  /// Normaliza el campo evaluations sin importar si la API devuelve
  /// List<EvaluationDto> o Map<userId, scores> (formato legado).
  List<dynamic> _parseEvaluations(dynamic evalsData) {
    if (evalsData is List) return evalsData;

    if (evalsData is Map) {
      final result = <dynamic>[];
      for (final entry in evalsData.entries) {
        if (entry.key == 'calificacion') continue;
        final userId = entry.key as String;
        final scores = entry.value;
        if (scores is! Map) continue;
        final double weighted = scores.values
            .fold(0.0, (s, e) => s + ((e as num?)?.toDouble() ?? 0.0));
        result.add({
          'id': userId,
          'docenteId': userId,
          'docenteNombre': 'Evaluador',
          'tipo': 'evaluacion',
          'status': 'completed',
          'calificacion': weighted * (100 / (scores.length * 5)),
          'weightedTotalScore': weighted,
          'criteria': scores.entries
              .map((c) => {
                    'id': c.key,
                    'name': c.key,
                    'score': (c.value as num).toDouble(),
                    'weight': 1.0,
                  })
              .toList(),
        });
      }
      return result;
    }

    return [];
  }

  /// Ensambla el [Map] que cumple el contrato de POST /api/evaluations.
  Map<String, dynamic> _buildLegacyPayload({
    required String projectId,
    required String docenteId,
    required String docenteNombre,
    required String tipo,
    required List<Map<String, dynamic>> criteria,
    required double weightedTotalScore,
    String? generalFeedback,
  }) {
    final calificacion = _normalizeScore(criteria, weightedTotalScore);
    final contenido = _buildContenido(
      criteria: criteria,
      calificacion: calificacion,
      tipo: tipo,
      generalFeedback: generalFeedback,
    );

    return {
      'projectId': projectId,
      'docenteId': docenteId,
      'docenteNombre': docenteNombre,
      'tipo': tipo,
      'contenido': contenido,
      if (tipo == 'oficial') 'calificacion': calificacion,
    };
  }

  /// Normalización lineal del score a escala 0–100.
  int _normalizeScore(
    List<Map<String, dynamic>> criteria,
    double weightedTotalScore,
  ) {
    const maxScorePerCriterion = 5.0;
    final maximumPossibleScore = criteria.fold<double>(
      0.0,
      (sum, c) =>
          sum + ((c['weight'] as num?)?.toDouble() ?? 0.0) * maxScorePerCriterion,
    );
    if (maximumPossibleScore <= 0) return 0;
    return ((weightedTotalScore / maximumPossibleScore) * 100)
        .round()
        .clamp(0, 100);
  }

  /// Serializa el detalle de la evaluación al campo `contenido` (texto legible).
  String _buildContenido({
    required List<Map<String, dynamic>> criteria,
    required int calificacion,
    required String tipo,
    String? generalFeedback,
  }) {
    final buf = StringBuffer();
    final tipoLabel =
        tipo == 'oficial' ? 'Evaluación Oficial' : 'Sugerencia de Evaluación';

    buf.writeln('$tipoLabel | Puntuación Total: $calificacion / 100');
    buf.writeln('━' * 45);
    buf.writeln();

    for (final c in criteria) {
      final name = (c['name'] as String? ?? 'Criterio').trim();
      final weight = (c['weight'] as num?)?.toDouble() ?? 0.0;
      final score = (c['score'] as num?)?.toDouble() ?? 0.0;
      final comment = c['comment'] as String?;

      final weightPercent = (weight * 100).toStringAsFixed(0);
      final contribution = score * weight;
      final maxContribution = 5.0 * weight;

      buf.writeln('[$name | Peso: $weightPercent%]');
      buf.writeln('  Puntuación: ${score.toStringAsFixed(0)} / 5');
      buf.writeln(
        '  Aporte al total: ${contribution.toStringAsFixed(2)} / ${maxContribution.toStringAsFixed(2)} pts',
      );
      if (comment != null && comment.trim().isNotEmpty) {
        buf.writeln('  Comentario: "${comment.trim()}"');
      }
      if (c != criteria.last) buf.writeln('---');
    }

    final feedback = generalFeedback?.trim();
    if (feedback != null && feedback.isNotEmpty) {
      buf.writeln();
      buf.writeln('━' * 45);
      buf.writeln('Retroalimentación General:');
      buf.writeln('"$feedback"');
    }

    return buf.toString().trimRight();
  }
}
