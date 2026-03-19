// bootstrap.dart — Inicialización centralizada (patrón VGV)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/notifications/notification_service.dart';
import 'core/sync/sync_worker.dart';

typedef AppBuilder = Widget Function();

// Overrides de Riverpod inyectados por cada punto de entrada (main_xxx.dart)
typedef ProviderOverrides = List<Override>;

/// URL de producción que puede estar durmiendo en Render free tier
const _renderPingUrl = 'https://integradorhub.onrender.com/api/health';

/// Ping silencioso para despertar la API de Render antes de que el usuario
/// intente hacer login. Fire-and-forget: nunca bloquea el arranque.
void _warmupApi() {
  Future.microtask(() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(_renderPingUrl));
      req.headers.set('User-Agent', 'Biofrost-warmup');
      final res = await req.close();
      await res.drain<void>();
      client.close();
    } catch (_) {
      // Ignorar cualquier error — el objetivo es solo despertar el servidor
    }
  });
}

Future<void> bootstrap(
  AppBuilder builder, {
  ProviderOverrides overrides = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Despertar API de Render en paralelo, sin bloquear la inicialización
  _warmupApi();

  // Locale para intl/DateFormat — no depende de Firebase, puede correr primero
  await initializeDateFormatting('es', null);

  // Paso 3: Firebase ya fue inicializado en main() antes de llamar bootstrap().
  // NotificationService se inicializa aquí de forma secuencial y segura.
  await NotificationService.instance.initialize();

  // SyncWorker: se inicializa después de runApp para tener acceso al
  // ProviderScope. Usamos un observer que lo arranca en el primer frame.
  final container = ProviderContainer(overrides: overrides);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: builder(),
    ),
  );

  // Inicializar el SyncWorker tras el primer frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(syncWorkerProvider).init();
  });
}
