// core/services/api_service.dart — Cliente HTTP centralizado con Dio
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

const _tokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

const _storage = FlutterSecureStorage();
final _logger = Logger();

/// Provider del Dio configurado
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.fromEnvironment(AppEnvironment.production).baseUrl,
      // Render free tier puede tardar 50-90 s en cold-start; 90 s evita
      // el DioExceptionType.receiveTimeout durante el primer login del día.
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Logger en debug
  dio.interceptors.add(
    PrettyDioLogger(requestBody: true, responseBody: true, error: true),
  );

  // Auth interceptor — inyecta Bearer token y refresca en 401
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken(dio);
          if (refreshed) {
            // Reintento automatico con nuevo token
            final token = await _storage.read(key: _tokenKey);
            final opts = err.requestOptions
              ..headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
        }
        return handler.next(err);
      },
    ),
  );

  return dio;
});

Future<bool> _tryRefreshToken(Dio dio) async {
  try {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    final res = await dio.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final newToken = res.data['accessToken'] as String?;
    final newRefresh = res.data['refreshToken'] as String?;

    if (newToken != null) {
      await _storage.write(key: _tokenKey, value: newToken);
      if (newRefresh != null) {
        await _storage.write(key: _refreshTokenKey, value: newRefresh);
      }
      return true;
    }
  } catch (e) {
    _logger.w('Token refresh failed', error: e);
  }
  return false;
}

/// Convierte DioException en AppException
AppException handleDioError(DioException e) {
  _logger.e('API Error', error: e.message, stackTrace: e.stackTrace);
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.connectionError =>
      const NetworkException(),
    // receiveTimeout → el servidor respondió tarde (ej. Render cold-start)
    DioExceptionType.receiveTimeout => const TimeoutException(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
        401 => const UnauthorizedException(),
        403 => const ForbiddenException(),
        404 => const NotFoundException(),
        422 || 400 => ValidationException(
            (e.response?.data['message'] ?? 'Datos inválidos').toString(),
          ),
        _ => const ServerException(),
      },
    _ => const UnknownException(),
  };
}

/// Stores tokens after login
Future<void> persistTokens(String access, String refresh) async {
  await _storage.write(key: _tokenKey, value: access);
  await _storage.write(key: _refreshTokenKey, value: refresh);
}

/// Clears all stored tokens
Future<void> clearTokens() async {
  await _storage.deleteAll();
}

/// Returns stored access token
Future<String?> getAccessToken() => _storage.read(key: _tokenKey);
