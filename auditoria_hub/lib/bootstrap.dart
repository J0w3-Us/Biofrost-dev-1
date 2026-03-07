// bootstrap.dart — Inicialización centralizada (patrón VGV)
import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'firebase_options.dart';

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

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }
  await NotificationService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: overrides,
      child: builder(),
    ),
  );
}
