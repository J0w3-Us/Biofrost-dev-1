// core/sync/outbox_item.dart
// Modelo que representa un item de la Bandeja de Salida (Outbox Pattern).
// Cada evaluación enviada sin conexión queda registrada aquí hasta que
// el SyncWorker la confirme contra el backend.

import 'dart:convert';

enum OutboxStatus {
  /// Guardada localmente, esperando sinconizización.
  pending,

  /// El SyncWorker la está procesando en este momento.
  processing,

  /// Falló después de [maxAttempts] reintentos. Requiere acción del usuario.
  failed,
}

class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.operation,
    required this.payload,
    required this.projectId,
    required this.status,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });

  /// UUID generado en el cliente — garantiza idempotencia.
  final String id;

  /// Tipo de operación: 'submit_evaluation' | 'toggle_visibility'.
  final String operation;

  /// JSON con toda la información necesaria para reproducir la llamada a la API.
  /// Incluye el Command completo + datos del docente (uid, nombre, tipo).
  final Map<String, dynamic> payload;

  /// ID del proyecto afectado — para invalidar el caché tras sincronizar.
  final String projectId;

  final OutboxStatus status;

  /// Timestamp de creación en ms epoch. La cola se procesa en orden FIFO.
  final int createdAt;

  /// Número de intentos de envío fallidos. Máximo = [SyncWorker.maxAttempts].
  final int attempts;

  /// Último mensaje de error para debug y visualización en la UI.
  final String? lastError;

  // ── Serialización SQLite ─────────────────────────────────────────────────

  Map<String, dynamic> toRow() => {
        'id': id,
        'operation': operation,
        'payload': jsonEncode(payload),
        'project_id': projectId,
        'status': status.name,
        'created_at': createdAt,
        'attempts': attempts,
        'last_error': lastError,
      };

  factory OutboxItem.fromRow(Map<String, dynamic> row) => OutboxItem(
        id: row['id'] as String,
        operation: row['operation'] as String,
        payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        projectId: row['project_id'] as String,
        status: OutboxStatus.values.byName(row['status'] as String),
        createdAt: row['created_at'] as int,
        attempts: row['attempts'] as int,
        lastError: row['last_error'] as String?,
      );

  OutboxItem copyWith({
    OutboxStatus? status,
    int? attempts,
    String? lastError,
  }) =>
      OutboxItem(
        id: id,
        operation: operation,
        payload: payload,
        projectId: projectId,
        status: status ?? this.status,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );
}
