// main_development.dart — Desarrollo local (FLAVOR=development)
import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'app.dart';

void main() => bootstrap(
      () => const App(environment: AppEnvironment.development),
    );
