// main_development.dart — Desarrollo local (FLAVOR=development)
import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/services/api_service.dart';
import 'app.dart';

void main() => bootstrap(
      () => const App(environment: AppEnvironment.development),
      // Sobrescribir el envProvider para que el Dio apunte a localhost en el emulador
      overrides: [
        appEnvironmentProvider.overrideWithValue(AppEnvironment.development),
      ],
    );
