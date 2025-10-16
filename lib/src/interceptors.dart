// **************************************************************************
// Flugx GetX API Generator - Interceptors and Middleware
// **************************************************************************

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Types d'intercepteurs disponibles
enum InterceptorType {
  request,
  response,
  error,
}

/// Interface de base pour les intercepteurs
abstract class HttpInterceptor {
  InterceptorType get type;
  Future<void> intercept(dynamic data);
}

/// Configuration des intercepteurs
class InterceptorConfig {
  final bool enableLogging;
  final bool enableAuth;
  final bool enableRetry;
  final bool enableCache;
  final Duration? requestTimeout;
  final int? maxRetries;

  const InterceptorConfig({
    this.enableLogging = true,
    this.enableAuth = true,
    this.enableRetry = true,
    this.enableCache = false,
    this.requestTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });
}

/// Intercepteur de logging
class LoggingInterceptor implements HttpInterceptor {
  @override
  InterceptorType get type => InterceptorType.request;

  @override
  Future<void> intercept(dynamic data) async {
    if (data is Map<String, dynamic>) {
      print('🚀 API Request: ${data['method']} ${data['url']}');
      if (data['headers'] != null) {
        print('📋 Headers: ${jsonEncode(data['headers'])}');
      }
      if (data['body'] != null) {
        print('📦 Body: ${data['body']}');
      }
    }
  }
}

/// Intercepteur de réponse pour logging
class ResponseLoggingInterceptor implements HttpInterceptor {
  @override
  InterceptorType get type => InterceptorType.response;

  @override
  Future<void> intercept(dynamic data) async {
    if (data is http.Response) {
      print('✅ Response: ${data.statusCode}');
      if (data.statusCode >= 400) {
        print('❌ Error Body: ${data.body}');
      }
    }
  }
}

/// Intercepteur d'authentification automatique
class AuthInterceptor implements HttpInterceptor {
  final Future<Map<String, String>> Function() getAuthHeaders;

  AuthInterceptor(this.getAuthHeaders);

  @override
  InterceptorType get type => InterceptorType.request;

  @override
  Future<void> intercept(dynamic data) async {
    if (data is Map<String, dynamic> && data['headers'] != null) {
      final authHeaders = await getAuthHeaders();
      data['headers'].addAll(authHeaders);
    }
  }
}

/// Intercepteur de retry avec backoff exponentiel
class RetryInterceptor implements HttpInterceptor {
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  InterceptorType get type => InterceptorType.error;

  @override
  Future<void> intercept(dynamic data) async {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      final attemptCount = data['attemptCount'] ?? 0;
      final response = data['response'];

      // Retry pour erreurs réseau ou serveur
      if (attemptCount < maxRetries &&
          (error is Exception || (response is http.Response &&
              (response.statusCode >= 500 || response.statusCode == 429)))) {

        final delay = initialDelay * (1 << attemptCount); // Backoff exponentiel
        await Future.delayed(delay);

        data['shouldRetry'] = true;
        print('🔄 Retrying request (attempt ${attemptCount + 1}/${maxRetries}) after ${delay.inSeconds}s');
      }
    }
  }
}

// Note: Cache functionality is now handled by SmartCache in error_handling.dart

/// Gestionnaire d'intercepteurs
class InterceptorManager {
  final List<HttpInterceptor> _interceptors = [];

  void addInterceptor(HttpInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  void removeInterceptor(HttpInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  Future<void> executeInterceptors(InterceptorType type, dynamic data) async {
    final relevantInterceptors = _interceptors.where((i) => i.type == type);

    for (final interceptor in relevantInterceptors) {
      try {
        await interceptor.intercept(data);
      } catch (e) {
        print('❌ Interceptor error: $e');
        // Continue avec les autres intercepteurs même en cas d'erreur
      }
    }
  }

  /// Méthode utilitaire pour créer un manager pré-configuré
  static InterceptorManager createDefault(InterceptorConfig config) {
    final manager = InterceptorManager();

    if (config.enableLogging) {
      manager.addInterceptor(LoggingInterceptor());
      manager.addInterceptor(ResponseLoggingInterceptor());
    }

    if (config.enableRetry) {
      manager.addInterceptor(RetryInterceptor(maxRetries: config.maxRetries ?? 3));
    }

    // Note: Cache est maintenant géré par SmartCache dans le code généré
    // L'auth interceptor sera ajouté dynamiquement dans le code généré

    return manager;
  }
}
