// **************************************************************************
// Flugx GetX API Generator - Enhanced Error Handling & Retry
// **************************************************************************

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Callback type pour les listeners de connectivité
typedef VoidCallback = void Function();

/// Exception de base pour les erreurs API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Types d'erreurs possibles
enum ErrorType {
  network,
  authentication,
  authorization,
  validation,
  server,
  rateLimit,
  timeout,
  unknown,
}

/// Configuration du retry
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool retryOnServerErrors;
  final bool retryOnNetworkErrors;
  final bool retryOnRateLimit;
  final Set<int> retryableStatusCodes;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryOnServerErrors = true,
    this.retryOnNetworkErrors = true,
    this.retryOnRateLimit = true,
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
  });

  /// Calcule le délai pour une tentative donnée
  Duration calculateDelay(int attempt) {
    final delay = initialDelay * (backoffMultiplier * (attempt - 1));
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Configuration du cache
class CacheConfig {
  final Duration defaultTtl;
  final int maxCacheSize;
  final bool enableBackgroundRefresh;
  final bool cachePostRequests;
  final Set<String> cacheableUrls;
  final Set<String> nonCacheableUrls;

  const CacheConfig({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxCacheSize = 100,
    this.enableBackgroundRefresh = false,
    this.cachePostRequests = false,
    this.cacheableUrls = const {},
    this.nonCacheableUrls = const {},
  });
}

/// Entrée de cache avec métadonnées
class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String etag;
  final String lastModified;
  final int accessCount;
  final DateTime lastAccessed;

  CacheEntry({
    required this.key,
    required this.data,
    required this.expiresAt,
    this.etag = '',
    this.lastModified = '',
    DateTime? createdAt,
    this.accessCount = 0,
    DateTime? lastAccessed,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastAccessed = lastAccessed ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get shouldRefresh => isExpired || (accessCount > 10);

  CacheEntry access() {
    return CacheEntry(
      key: key,
      data: data,
      expiresAt: expiresAt,
      etag: etag,
      lastModified: lastModified,
      createdAt: createdAt,
      accessCount: accessCount + 1,
      lastAccessed: DateTime.now(),
    );
  }

  CacheEntry withNewData(dynamic newData, {required Duration ttl}) {
    return CacheEntry(
      key: key,
      data: newData,
      expiresAt: DateTime.now().add(ttl),
      etag: etag,
      lastModified: lastModified,
      createdAt: createdAt,
      accessCount: 0,
      lastAccessed: DateTime.now(),
    );
  }
}

/// Cache intelligent avec LRU eviction
class SmartCache {
  final CacheConfig config;
  final Map<String, CacheEntry> _cache = {};
  final List<String> _accessOrder = [];

  SmartCache(this.config);

  /// Récupère une entrée du cache
  CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      if (entry?.isExpired == true) {
        _cache.remove(key);
        _accessOrder.remove(key);
      }
      return null;
    }

    // Met à jour l'ordre d'accès pour LRU
    _updateAccessOrder(key);
    _cache[key] = entry.access();

    return entry;
  }

  /// Ajoute ou met à jour une entrée dans le cache
  void put(String key, dynamic data, {Duration? ttl, String etag = '', String lastModified = ''}) {
    final actualTtl = ttl ?? config.defaultTtl;
    final entry = CacheEntry(
      key: key,
      data: data,
      expiresAt: DateTime.now().add(actualTtl),
      etag: etag,
      lastModified: lastModified,
    );

    // Vérifie la taille maximale du cache
    if (_cache.length >= config.maxCacheSize && !_cache.containsKey(key)) {
      _evictLruEntry();
    }

    _cache[key] = entry;
    _updateAccessOrder(key);
  }

  /// Supprime une entrée du cache
  void remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Vide le cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Vérifie si une URL doit être cachée
  bool shouldCacheUrl(String url, String method) {
    // Ne cache que les GET par défaut
    if (method.toUpperCase() != 'GET' && !config.cachePostRequests) {
      return false;
    }

    // URLs explicitement non cachables
    if (config.nonCacheableUrls.any((pattern) => url.contains(pattern))) {
      return false;
    }

    // URLs explicitement cachables ou tout par défaut
    return config.cacheableUrls.any((pattern) => url.contains(pattern)) ||
           config.cacheableUrls.isEmpty;
  }

  /// Génère une clé de cache pour une requête
  String generateCacheKey(String url, Map<String, String>? headers, dynamic body) {
    final keyBuffer = StringBuffer(url);

    if (body != null) {
      keyBuffer.write('?body=${jsonEncode(body)}');
    }

    // Ajoute des headers importants pour la clé
    final importantHeaders = ['Accept', 'Accept-Language', 'Authorization'];
    for (final header in importantHeaders) {
      if (headers?.containsKey(header) == true) {
        keyBuffer.write('&$header=${headers![header]}');
      }
    }

    return keyBuffer.toString();
  }

  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  void _evictLruEntry() {
    if (_accessOrder.isNotEmpty) {
      final lruKey = _accessOrder.first;
      _cache.remove(lruKey);
      _accessOrder.removeAt(0);
    }
  }

  /// Statistiques du cache
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where((e) => !e.isExpired).length;
    final expiredEntries = _cache.length - validEntries;

    return {
      'total_entries': _cache.length,
      'valid_entries': validEntries,
      'expired_entries': expiredEntries,
      'hit_rate': _calculateHitRate(),
    };
  }

  double _calculateHitRate() {
    if (_cache.isEmpty) return 0.0;
    final totalAccess = _cache.values.fold<int>(0, (sum, e) => sum + e.accessCount);
    return totalAccess > 0 ? (_cache.length / totalAccess) * 100 : 0.0;
  }
}

/// Gestionnaire d'erreurs amélioré
class ErrorHandler {
  final RetryConfig retryConfig;

  ErrorHandler(this.retryConfig);

  /// Analyse une erreur et retourne le type approprié
  ErrorType analyzeError(dynamic error, http.Response? response) {
    if (error is Exception && response == null) {
      return ErrorType.network;
    }

    if (response != null) {
      switch (response.statusCode) {
        case 401:
          return ErrorType.authentication;
        case 403:
          return ErrorType.authorization;
        case 400:
        case 422:
          return ErrorType.validation;
        case 429:
          return ErrorType.rateLimit;
        case 408:
        case 504:
          return ErrorType.timeout;
        case 500:
        case 502:
        case 503:
          return ErrorType.server;
        default:
          if (response.statusCode >= 500) {
            return ErrorType.server;
          }
          return ErrorType.unknown;
      }
    }

    return ErrorType.unknown;
  }

  /// Détermine si une erreur est retry-able
  bool isRetryable(ErrorType errorType, int? statusCode) {
    switch (errorType) {
      case ErrorType.network:
        return retryConfig.retryOnNetworkErrors;
      case ErrorType.server:
        return retryConfig.retryOnServerErrors;
      case ErrorType.rateLimit:
        return retryConfig.retryOnRateLimit;
      case ErrorType.timeout:
        return true; // Toujours retry timeout
      default:
        return retryConfig.retryableStatusCodes.contains(statusCode);
    }
  }

  /// Crée une exception appropriée selon le type d'erreur
  Exception createException(ErrorType errorType, String message, {int? statusCode, dynamic data}) {
    switch (errorType) {
      case ErrorType.network:
        return NetworkException(message);
      case ErrorType.authentication:
        return AuthException(message, statusCode: statusCode);
      case ErrorType.validation:
        return ValidationException(message, data);
      default:
        return ApiException(message, statusCode: statusCode, data: data);
    }
  }

  /// Stratégie de retry avec backoff exponentielle
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation,
    bool Function(dynamic) shouldRetry,
  ) async {
    int attempt = 0;
    dynamic lastError;

    while (attempt < retryConfig.maxAttempts) {
      try {
        final result = await operation();
        return result;
      } catch (error) {
        lastError = error;
        attempt++;

        if (attempt >= retryConfig.maxAttempts || !shouldRetry(error)) {
          break;
        }

        final delay = retryConfig.calculateDelay(attempt);
        print('🔄 Retrying after ${delay.inSeconds}s (attempt $attempt/${retryConfig.maxAttempts})');
        await Future.delayed(delay);
      }
    }

    throw lastError ?? Exception('Unknown error');
  }
}

/// Gestionnaire de réseau pour détecter la connectivité
class NetworkManager {
  static const Duration _stabilityDuration = Duration(seconds: 5);

  bool _isOnline = true;
  DateTime? _lastConnectivityCheck;
  final List<VoidCallback> _listeners = [];

  bool get isOnline => _isOnline;

  void addConnectivityListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeConnectivityListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      final online = response.statusCode == 200;
      _updateConnectivityStatus(online);
      return online;
    } catch (_) {
      _updateConnectivityStatus(false);
      return false;
    }
  }

  void _updateConnectivityStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _lastConnectivityCheck = DateTime.now();

      // Notifie tous les listeners
      for (final listener in _listeners) {
        try {
          listener();
        } catch (e) {
          // Ignore les erreurs des listeners
        }
      }

      print('🌐 Connectivity changed: ${online ? 'online' : 'offline'}');
    }
  }

  /// Vérifie si le réseau est stable depuis assez longtemps
  bool isNetworkStable() {
    if (!_isOnline || _lastConnectivityCheck == null) return false;
    return DateTime.now().difference(_lastConnectivityCheck!) > _stabilityDuration;
  }
}

/// Classes d'exceptions spécialisées
class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class AuthException extends ApiException {
  AuthException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

class ValidationException extends ApiException {
  ValidationException(String message, dynamic data)
      : super(message, data: data);
}

/// Exception pour rate limiting
class RateLimitException extends ApiException {
  final Duration retryAfter;

  RateLimitException(String message, this.retryAfter)
      : super(message, statusCode: 429);
}

/// Exception de timeout
class TimeoutException extends NetworkException {
  TimeoutException(String message) : super(message);
}
