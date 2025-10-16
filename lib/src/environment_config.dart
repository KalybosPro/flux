// **************************************************************************
// Flugx GetX API Generator - Multi-Environment Configuration (Simplified)
// **************************************************************************

/// Callback type pour compatibilité
typedef VoidCallback = void Function();

/// Environnements supportés
enum Environment {
  development,
  staging,
  production,
  testing,
}

/// Configuration simple d'environnement (sans dépendances complexes pour l'instant)
class SimpleEnvironmentConfig {
  final Environment environment;
  final String baseUrl;
  final String? apiVersion;
  final Map<String, String> headers;
  final Duration timeout;
  final Map<String, dynamic> customConfig;

  const SimpleEnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    this.apiVersion,
    this.headers = const {},
    this.timeout = const Duration(seconds: 30),
    this.customConfig = const {},
  });

  /// Construit l'URL complète pour un endpoint
  String buildUrl(String endpoint) {
    final url = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final version = apiVersion != null ? '/$apiVersion' : '';
    return '$baseUrl$version$url';
  }

  /// Obtient les headers complets incluant ceux spécifiques à l'environnement
  Map<String, String> getFullHeaders({Map<String, String>? extraHeaders}) {
    return {
      ...headers,
      ...?extraHeaders,
    };
  }

  /// Vérifie si c'est un environnement de production
  bool get isProduction => environment == Environment.production;

  /// Vérifie si c'est un environnement de développement
  bool get isDevelopment => environment == Environment.development;

  /// Vérifie si c'est un environnement de test
  bool get isTesting => environment == Environment.testing;
}

/// Gestionnaire de configurations d'environnement simplifié
class EnvironmentManager {
  static EnvironmentManager? _instance;
  Environment _currentEnvironment = Environment.development;
  final Map<Environment, SimpleEnvironmentConfig> _configs = {};

  EnvironmentManager._();

  static EnvironmentManager get instance {
    _instance ??= EnvironmentManager._();
    return _instance!;
  }

  /// Configure l'environnement actuel
  void setEnvironment(Environment env, {
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? customConfig,
  }) {
    _currentEnvironment = env;
    final config = SimpleEnvironmentConfig(
      environment: env,
      baseUrl: baseUrl ?? _getDefaultBaseUrl(env),
      apiVersion: 'v1',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      },
      timeout: _getDefaultTimeout(env),
      customConfig: customConfig ?? {},
    );
    _configs[env] = config;
  }

  /// Obtient la configuration de l'environnement actuel
  SimpleEnvironmentConfig get currentConfig => _configs[_currentEnvironment]!;

  /// Change d'environnement
  void switchEnvironment(Environment env) {
    if (_configs.containsKey(env)) {
      _currentEnvironment = env;
    } else {
      throw ArgumentError('Configuration not found for environment: $env');
    }
  }

  String _getDefaultBaseUrl(Environment env) {
    switch (env) {
      case Environment.development:
        return 'http://localhost:3000';
      case Environment.staging:
        return 'https://api-staging.example.com';
      case Environment.production:
        return 'https://api.example.com';
      case Environment.testing:
        return 'http://localhost:3000';
    }
  }

  Duration _getDefaultTimeout(Environment env) {
    switch (env) {
      case Environment.development:
        return const Duration(seconds: 60);
      case Environment.staging:
        return const Duration(seconds: 45);
      case Environment.production:
        return const Duration(seconds: 30);
      case Environment.testing:
        return const Duration(seconds: 10);
    }
  }
}

/// Utilitaires pour charger la configuration
class EnvironmentLoader {
  static Environment detectEnvironment([Map<String, String>? envVars]) {
    final env = envVars ?? Platform.environment;
    final envString = env['FLUGX_ENV'] ?? env['ENV'] ?? 'development';

    switch (envString.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      case 'test':
      case 'testing':
        return Environment.testing;
      case 'dev':
      case 'development':
      default:
        return Environment.development;
    }
  }

  static String? getEnvVar(String key, [Map<String, String>? envVars]) {
    return (envVars ?? Platform.environment)[key];
  }
}

// Mock des dépendances pour CLI
class Platform {
  static Map<String, String> get environment => {};
}
