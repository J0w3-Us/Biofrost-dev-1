// main_staging.dart — Staging (FLAVOR=staging)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    () => const App(environment: AppEnvironment.staging),
  );
}
