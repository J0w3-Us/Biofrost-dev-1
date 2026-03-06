// bootstrap.dart — Inicialización centralizada (patrón VGV)
import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';

typedef AppBuilder = Widget Function();

/// URL de producción que puede estar durmiendo en Render free tier
const _renderPingUrl = 'https://integradorhub.onrender.com/health';

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

Future<void> bootstrap(AppBuilder builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Despertar API de Render en paralelo, sin bloquear la inicialización
  _warmupApi();

  await Firebase.initializeApp();
  await NotificationService.instance.initialize();

  runApp(
    ProviderScope(
      child: builder(),
    ),
  );
}
