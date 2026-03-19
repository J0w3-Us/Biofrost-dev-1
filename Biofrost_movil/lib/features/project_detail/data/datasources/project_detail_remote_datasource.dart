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
          
      final evalsData = responses[1].data;
      List<dynamic> parsedEvals = [];
      if (evalsData is List) {
        parsedEvals = evalsData;
      } else if (evalsData is Map) {
        final entries = evalsData.entries.where((e) => e.key != 'calificacion');
        for (final entry in entries) {
          final userId = entry.key;
          final scores = entry.value;
          if (scores is Map) {
            final double weighted = scores.values.fold(
                0.0, (s, e) => s + ((e as num?)?.toDouble() ?? 0.0));
            parsedEvals.add({
              'id': userId,
              'docenteId': userId,
              'docenteNombre': 'Evaluador', 
              'tipo': 'evaluacion',
              'status': 'completed',
              'calificacion': weighted * (100 / (scores.length * 5)), // Approximate 0-100 scale
              'weightedTotalScore': weighted,
              'criteria': scores.entries.map((c) => {
                    'id': c.key,
                    'name': c.key,
                    'score': (c.value as num).toDouble(),
                    'weight': 1.0,
                  }).toList(),
            });
          }
        }
      }
      detailJson['evaluations'] = parsedEvals;

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

  /// RF-04: Envía evaluación al backend mediante el Patrón Adaptador.
  ///
  /// Transforma el modelo rico de rúbricas (N criterios con pesos y scores)
  /// al contrato simplificado de la API legada:
  ///   POST /api/evaluations → { projectId, docenteId, docenteNombre,
  ///                             tipo, contenido (String), calificacion (int 0-100) }
  ///
  /// El Datasource es la única capa que conoce este contrato. El Notifier
  /// y los Widgets permanecen completamente desacoplados del formato legado.
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
      // ── ADAPTADOR: Construcción del payload legado ─────────────────────────
      final legacyPayload = _buildLegacyPayload(
        projectId: projectId,
        docenteId: docenteId,
        docenteNombre: docenteNombre,
        tipo: tipo,
        criteria: criteria,
        weightedTotalScore: weightedTotalScore,
        generalFeedback: generalFeedback,
      );
      // ──────────────────────────────────────────────────────────────────────

      await _dio.post(ApiEndpoints.evaluations, data: legacyPayload);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  // ── Métodos privados del Adaptador ─────────────────────────────────────────

  /// Ensambla el Map que cumple el contrato de POST /api/evaluations.
  /// Solo incluye los campos que la API acepta; nunca envía campos extras
  /// como "criteria" o "weightedTotalScore" que el backend rechazaría.
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
      // calificacion solo se envía para evaluaciones oficiales (requerimiento API).
      if (tipo == 'oficial') 'calificacion': calificacion,
    };
  }

  /// TRANSFORMACIÓN MATEMÁTICA: Normalización lineal de score a escala 0–100.
  ///
  /// Fórmula: calificacion = round( (scoreObtenido / maxPosible) × 100 )
  ///
  /// El denominador [maximumPossibleScore] se calcula dinámicamente iterando
  /// los criterios (score máximo = 5 por escala de rúbrica). Nunca se hardcodea,
  /// por lo que la fórmula es robusta a cambios en el motor de rúbricas.
  int _normalizeScore(
    List<Map<String, dynamic>> criteria,
    double weightedTotalScore,
  ) {
    // Calcular el score máximo posible: suma de (5 × peso) de cada criterio.
    // La escala de puntuación por criterio es 1–5.
    const maxScorePerCriterion = 5.0;
    final maximumPossibleScore = criteria.fold<double>(
      0.0,
      (sum, c) => sum + ((c['weight'] as num?)?.toDouble() ?? 0.0) * maxScorePerCriterion,
    );

    if (maximumPossibleScore <= 0) return 0;

    // Normalización lineal + redondeo + clamp de seguridad defensiva.
    final normalized = (weightedTotalScore / maximumPossibleScore) * 100;
    return normalized.round().clamp(0, 100);
  }

  /// SERIALIZACIÓN DEL TEXTO: Construye el campo `contenido` como un bloque
  /// de texto estructurado y legible en tres secciones:
  ///   1. Encabezado de resumen.
  ///   2. Detalle desglosado por criterio.
  ///   3. Retroalimentación general (opcional).
  ///
  /// Usa StringBuffer para eficiencia en lugar de concatenación con +.
  String _buildContenido({
    required List<Map<String, dynamic>> criteria,
    required int calificacion,
    required String tipo,
    String? generalFeedback,
  }) {
    final buf = StringBuffer();
    final tipoLabel = tipo == 'oficial' ? 'Evaluación Oficial' : 'Sugerencia de Evaluación';

    // ── Sección 1: Encabezado ──────────────────────────────────────────────
    buf.writeln('$tipoLabel | Puntuación Total: $calificacion / 100');
    buf.writeln('━' * 45);
    buf.writeln();

    // ── Sección 2: Detalle por criterio ───────────────────────────────────
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

      // Separador entre criterios (omitir en el último).
      if (c != criteria.last) buf.writeln('---');
    }

    // ── Sección 3: Retroalimentación general (opcional) ───────────────────
    final feedback = generalFeedback?.trim();
    if (feedback != null && feedback.isNotEmpty) {
      buf.writeln();
      buf.writeln('━' * 45);
      buf.writeln('Retroalimentación General:');
      buf.writeln('"$feedback"');
    }

    return buf.toString().trimRight();
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
