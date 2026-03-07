// core/services/api_service.dart — Cliente HTTP centralizado con Dio
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

final _logger = Logger();

/// Provider del entorno — se puede sobrescribir en main_xxx.dart
final appEnvironmentProvider = Provider<AppEnvironment>(
  (_) => AppEnvironment.production,
);

/// Provider del Dio configurado
/// El backend NO usa JWT: las rutas /auth/login y /auth/register son públicas.
/// La autenticación se realiza via Firebase UID (igual que el frontend web).
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  final config = AppConfig.fromEnvironment(env);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      // Render free tier tarda 50-90 s en cold-start al primer request del día.
      // connectTimeout debe ser >= ese tiempo para no fallar antes de recibir respuesta.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Logger de requests/responses (solo en dev/staging)
  if (config.isDev || config.isStaging) {
    dio.interceptors.add(
      PrettyDioLogger(requestBody: true, responseBody: true, error: true),
    );
  }

  return dio;
});

/// Convierte DioException en AppException con mensajes claros
AppException handleDioError(DioException e) {
  _logger.e(
    'API Error [${e.requestOptions.method} ${e.requestOptions.path}]',
    error: e.message,
    stackTrace: e.stackTrace,
  );

  // Log detallado del response para facilitar debug
  if (e.response != null) {
    _logger.e('Response ${e.response?.statusCode}: ${e.response?.data}');
  }

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.connectionError =>
      const NetworkException(),
    // receiveTimeout durante cold-start de Render (servidor tardó en responder)
    DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
        401 => const UnauthorizedException(),
        403 => const ForbiddenException(),
        404 => const NotFoundException(),
        422 || 400 => ValidationException(_extractErrorMessage(e)),
        _ => const ServerException(),
      },
    _ => const UnknownException(),
  };
}

/// Extrae mensaje de error de forma segura, soportando JSON y HTML
String _extractErrorMessage(DioException e) {
  try {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['Message'] ?? 'Datos inválidos')
          .toString();
    }
    if (data is String && data.isNotEmpty && !data.trimLeft().startsWith('<')) {
      return data;
    }
  } catch (_) {}
  return 'Datos inválidos';
}
