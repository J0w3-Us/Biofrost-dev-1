// main_development.dart — Desarrollo local (FLAVOR=development)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // Paso 1: binding + Firebase ANTES de que bootstrap() acceda a cualquier
  // servicio que dependa de Firebase (ej. NotificationService).
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.apps.isEmpty protege el caso normal; el try-catch absorbe
  // el error 'duplicate-app' que ocurre en Hot Restart (VM reiniciada
  // pero SDK nativo no destruido).
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }
  await bootstrap(
    () => const App(environment: AppEnvironment.development),
    // Sobrescribir el envProvider (ahora configurado para apuntar a Render en app_config.dart)
    overrides: [
      appEnvironmentProvider.overrideWithValue(AppEnvironment.development),
    ],
  );
}
