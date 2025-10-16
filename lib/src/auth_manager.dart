// **************************************************************************
// Flugx GetX API Generator - Authentication Manager
// **************************************************************************

import 'dart:convert';

/// Enumération des types d'authentification supportés
enum AuthType {
  none,
  bearer,
  basic,
  apiKey,
  oauth2,
}

/// Configuration d'authentification
class AuthConfig {
  final AuthType type;
  final String? token;
  final String? apiKey;
  final String? username;
  final String? password;
  final String? tokenUrl;
  final String? clientId;
  final String? clientSecret;
  final int? tokenExpiryBuffer; // secondes avant expiration pour refresh

  const AuthConfig({
    this.type = AuthType.none,
    this.token,
    this.apiKey,
    this.username,
    this.password,
    this.tokenUrl,
    this.clientId,
    this.clientSecret,
    this.tokenExpiryBuffer = 300, // 5 minutes par défaut
  });
}

/// Interface commune pour les gestionnaires d'authentification
abstract class AuthManager {
  Future<Map<String, String>> getAuthHeaders();
  Future<bool> isAuthenticated();
  Future<void> logout();
  Future<bool> refreshToken();
  AuthType get authType;
}

/// Gestionnaire d'authentification simple pour la génération de code
///NOTE: Dans le code généré, ce sera remplacé par une implémentation complète avec stockage persistant
class SimpleAuthManager implements AuthManager {
  final AuthConfig config;

  SimpleAuthManager(this.config);

  @override
  AuthType get authType => config.type;

  @override
  Future<Map<String, String>> getAuthHeaders() async {
    final headers = <String, String>{};

    switch (config.type) {
      case AuthType.bearer:
        if (config.token != null && config.token!.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${config.token}';
        }
        break;

      case AuthType.basic:
        if (config.username != null && config.password != null) {
          final credentials = base64Encode(
            utf8.encode('${config.username}:${config.password}'),
          );
          headers['Authorization'] = 'Basic $credentials';
        }
        break;

      case AuthType.apiKey:
        if (config.apiKey != null && config.apiKey!.isNotEmpty) {
          headers['X-API-Key'] = config.apiKey!;
        }
        break;

      case AuthType.oauth2:
        if (config.token != null && config.token!.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${config.token}';
        }
        break;

      case AuthType.none:
        break;
    }

    return headers;
  }

  @override
  Future<bool> isAuthenticated() async {
    switch (config.type) {
      case AuthType.none:
        return true;
      case AuthType.bearer:
      case AuthType.oauth2:
        return config.token != null && config.token!.isNotEmpty;
      case AuthType.basic:
        return config.username != null && config.password != null;
      case AuthType.apiKey:
        return config.apiKey != null && config.apiKey!.isNotEmpty;
    }
  }

  @override
  Future<void> logout() async {
    // Rien à faire pour la génération de code
  }

  @override
  Future<bool> refreshToken() async {
    // Simulé pour OAuth2 - dans le code généré, ce sera implémenté
    return config.type == AuthType.oauth2 && config.tokenUrl != null;
  }
}
