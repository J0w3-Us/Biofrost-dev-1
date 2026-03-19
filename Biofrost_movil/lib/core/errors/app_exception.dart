// core/errors/app_exception.dart — Jerarquia de excepciones (sealed class)
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// Error de conexion — sin internet o no se pudo alcanzar el servidor
class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión. Verifica tu red.']);
}

/// Timeout de respuesta — el servidor tardó demasiado (ej. Render cold-start)
class TimeoutException extends AppException {
  const TimeoutException(
      [super.message = 'El servidor tardó demasiado en responder.\n'
          'Puede estar iniciando (modo gratuito de Render). '
          'Intenta de nuevo en unos segundos.']);
}

/// Error 401 — token expirado o inválido
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Sesión expirada.']);
}

/// Error 403 — sin permisos para el recurso
class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Sin permisos para esta acción.']);
}

/// Error 404 — recurso no encontrado
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Recurso no encontrado.']);
}

/// Error 422/400 — validacion de negocio fallida
class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}

/// Error 5xx — error interno del servidor
class ServerException extends AppException {
  const ServerException(
      [super.message = 'Error en el servidor. Intenta más tarde.']);
}

/// Error generico / desconocido
class UnknownException extends AppException {
  const UnknownException([super.message = 'Ocurrió un error inesperado.']);
}

/// Conversion de DioException → AppException
AppException mapDioError(Object e) {
  // Importado en api_service.dart para evitar dependencia circular
  return const UnknownException();
}
