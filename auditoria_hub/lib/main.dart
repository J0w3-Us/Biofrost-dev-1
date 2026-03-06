// main.dart — Produccion (FLAVOR=production)
import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'app.dart';

void main() => bootstrap(
      () => const App(environment: AppEnvironment.production),
    );
