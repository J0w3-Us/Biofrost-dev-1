// core/config/app_config.dart — Configuracion por entorno
// Para cambiar el entorno activo, sobrescribe appEnvironmentProvider en main_xxx.dart
enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.baseUrl,
    required this.appTitle,
  });

  factory AppConfig.fromEnvironment(AppEnvironment env) {
    return switch (env) {
      AppEnvironment.development => const AppConfig._(
          environment: AppEnvironment.development,
          baseUrl: 'https://integradorhub.onrender.com',
          appTitle: 'Biofrost [DEV]',
        ),
      AppEnvironment.staging => const AppConfig._(
          environment: AppEnvironment.staging,
          baseUrl: 'https://integradorhub.onrender.com',
          appTitle: 'Biofrost [STAGING]',
        ),
      AppEnvironment.production => const AppConfig._(
          environment: AppEnvironment.production,
          baseUrl: 'https://integradorhub.onrender.com',
          appTitle: 'Biofrost',
        ),
    };
  }

  final AppEnvironment environment;
  final String baseUrl;
  final String appTitle;

  bool get isDev => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProd => environment == AppEnvironment.production;
  bool get showDebugBanner => isDev;
}
