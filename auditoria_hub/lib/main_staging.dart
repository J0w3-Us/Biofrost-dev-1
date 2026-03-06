// main_staging.dart — Staging (FLAVOR=staging)
import 'bootstrap.dart';
import 'core/config/app_config.dart';
import 'app.dart';

void main() => bootstrap(
      () => const App(environment: AppEnvironment.staging),
    );
