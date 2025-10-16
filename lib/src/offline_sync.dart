// **************************************************************************
// Flugx GetX API Generator - Offline Support & Synchronization
// **************************************************************************

// ignore_for_file: unused_field

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Utilisation d'une approche compatible CLI/Web
const bool kIsWeb = identical(0, 0.0); // Sera 'true' en JS, 'false' en Dart VM

/// Type d'opération hors ligne
enum OfflineOperation {
  create,
  update,
  delete,
  sync,
}

/// Configuration du mode hors ligne
class OfflineConfig {
  final bool enableOfflineMode;
  final bool enableBackgroundSync;
  final Duration syncInterval;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final bool syncOnConnectivityRestore;
  final bool prioritizeCriticalOperations;

  const OfflineConfig({
    this.enableOfflineMode = true,
    this.enableBackgroundSync = true,
    this.syncInterval = const Duration(minutes: 5),
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.syncOnConnectivityRestore = true,
    this.prioritizeCriticalOperations = true,
  });
}

/// Requête mise en file d'attente pour synchronisation
class QueuedRequest {
  final String id;
  final String url;
  final String method;
  final Map<String, String>? headers;
  final dynamic body;
  final OfflineOperation operation;
  final DateTime createdAt;
  final int retryCount;
  final bool isCritical;
  final String? tag; // Pour grouper des opérations liées

  QueuedRequest({
    required this.id,
    required this.url,
    required this.method,
    this.headers,
    this.body,
    this.operation = OfflineOperation.create,
    DateTime? createdAt,
    this.retryCount = 0,
    this.isCritical = false,
    this.tag,
  }) : this.createdAt = createdAt ?? DateTime.now();

  /// Convertit en Map pour la persistance
  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'method': method,
    'headers': headers,
    'body': body,
    'operation': operation.name,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'isCritical': isCritical,
    'tag': tag,
  };

  /// Crée depuis Map (persistence)
  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    id: json['id'],
    url: json['url'],
    method: json['method'],
    headers: json['headers'] != null
        ? Map<String, String>.from(json['headers'])
        : null,
    body: json['body'],
    operation: OfflineOperation.values.firstWhere(
      (e) => e.name == json['operation'],
      orElse: () => OfflineOperation.create,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    retryCount: json['retryCount'] ?? 0,
    isCritical: json['isCritical'] ?? false,
    tag: json['tag'],
  );

  /// Crée une copie avec retryCount incrémenté
  QueuedRequest withRetry() => QueuedRequest(
    id: id,
    url: url,
    method: method,
    headers: headers,
    body: body,
    operation: operation,
    createdAt: createdAt,
    retryCount: retryCount + 1,
    isCritical: isCritical,
    tag: tag,
  );
}

/// Statut de synchronisation
enum SyncStatus {
  idle,
  syncing,
  synced,
  failed,
  partial,
}

/// Gestionnaire de synchronisation hors ligne
class OfflineSyncManager {
  static const String _queueFile = 'flugx_offline_queue.json';
  static const String _failedOpsFile = 'flugx_failed_operations.json';

  final OfflineConfig config;
  final List<QueuedRequest> _requestQueue = [];
  final List<QueuedRequest> _failedOperations = [];
  SyncStatus _syncStatus = SyncStatus.idle;
  DateTime? _lastSyncAttempt;

  OfflineSyncManager(this.config) {
    if (config.enableOfflineMode) {
      _loadQueueFromStorage();
      _loadFailedOperationsFromStorage();
    }
  }

  SyncStatus get syncStatus => _syncStatus;
  bool get isOnline => true; // Sera connecté au NetworkManager
  bool get hasPendingOperations => _requestQueue.isNotEmpty;
  int get pendingOperationsCount => _requestQueue.length;

  /// Ajoute une requête à la file d'attente
  Future<void> queueRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    dynamic body,
    OfflineOperation operation = OfflineOperation.create,
    bool isCritical = false,
    String? tag,
  }) async {
    final request = QueuedRequest(
      id: _generateRequestId(),
      url: url,
      method: method,
      headers: headers,
      body: body,
      operation: operation,
      isCritical: isCritical,
      tag: tag,
    );

    _requestQueue.add(request);
    await _saveQueueToStorage();

    print('📋 Queued request: ${method.toUpperCase()} $url');

    // Synchronise immédiatement si en ligne et pas critique
    if (isOnline && !isCritical) {
      _scheduleSync();
    }
  }

  /// Synchronise toutes les opérations en file d'attente
  Future<SyncResult> syncNow() async {
    if (_syncStatus == SyncStatus.syncing) {
      return SyncResult(status: SyncStatus.partial, message: 'Sync already in progress');
    }

    if (!isOnline) {
      return SyncResult(status: SyncStatus.failed,
                       message: 'No internet connection');
    }

    _syncStatus = SyncStatus.syncing;
    _lastSyncAttempt = DateTime.now();

    try {
      final results = await _processQueue();
      final success = results.where((r) => r.success).length;
      final failed = results.where((r) => !r.success).length;

      _syncStatus = failed == 0 ? SyncStatus.synced :
                   success > 0 ? SyncStatus.partial :
                   SyncStatus.failed;

      await _saveQueueToStorage();
      await _saveFailedOperationsToStorage();

      return SyncResult(
        status: _syncStatus,
        syncedCount: success,
        failedCount: failed,
        results: results,
      );
    } catch (e) {
      _syncStatus = SyncStatus.failed;
      return SyncResult(status: SyncStatus.failed, message: 'Sync error: $e');
    }
  }

  /// Vide la file d'attente (utile après sync complète)
  Future<void> clearQueue() async {
    _requestQueue.clear();
    await _saveQueueToStorage();
  }

  /// Reconstruit la file d'attente à partir des opérations échouées
  Future<void> rebuildQueueFromFailed() async {
    final criticalFailed = _failedOperations.where((op) => op.isCritical).toList();
    _requestQueue.addAll(criticalFailed);
    _failedOperations.removeWhere((op) => op.isCritical);
    await _saveQueueToStorage();
    await _saveFailedOperationsToStorage();
  }

  /// Obtient des statistiques sur la file d'attente
  Map<String, dynamic> getQueueStats() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));

    final recent = _requestQueue.where((r) => r.createdAt.isAfter(oneHourAgo)).length;
    final today = _requestQueue.where((r) => r.createdAt.isAfter(oneDayAgo)).length;

    return {
      'total_queued': _requestQueue.length,
      'critical_operations': _requestQueue.where((r) => r.isCritical).length,
      'failed_operations': _failedOperations.length,
      'recent_operations': recent,
      'today_operations': today,
      'oldest_operation': _requestQueue.isNotEmpty
          ? _requestQueue.first.createdAt.toIso8601String()
          : null,
      'total_retry_attempts': _requestQueue.fold(0, (int? sum, r) => sum??0 + r.retryCount),
    };
  }

  void _scheduleSync() {
    if (!config.enableBackgroundSync) return;

    // Planifie une synchronisation dans l'intervalle configuré
    Future.delayed(config.syncInterval, () {
      if (hasPendingOperations && _syncStatus != SyncStatus.syncing) {
        syncNow();
      }
    });
  }

  Future<List<OperationResult>> _processQueue() async {
    final results = <OperationResult>[];
    final toRemove = <QueuedRequest>[];

    for (final request in _requestQueue) {
      try {
        final result = await _executeRequest(request);
        results.add(result);

        if (result.success || request.retryCount >= config.maxRetryAttempts) {
          toRemove.add(request);

          if (!result.success) {
            _failedOperations.add(request);
            print('❌ Operation failed permanently: ${request.method} ${request.url}');
          }
        } else {
          // Marque pour retry avec délai
          _scheduleRetry(request);
        }
      } catch (e) {
        print('❌ Request processing error: $e');
        results.add(OperationResult.success(request.id, false, error: e.toString()));
      }
    }

    _requestQueue.removeWhere((r) => toRemove.contains(r));
    return results;
  }

  Future<OperationResult> _executeRequest(QueuedRequest request) async {
    try {
      final uri = Uri.parse(request.url);
      final client = http.Client();

      late http.Response response;

      switch (request.method.toUpperCase()) {
        case 'GET':
          response = await client.get(uri, headers: request.headers);
          break;
        case 'POST':
          response = await client.post(
            uri,
            headers: request.headers,
            body: request.body is Map ? jsonEncode(request.body) : request.body,
          );
          break;
        case 'PUT':
          response = await client.put(
            uri,
            headers: request.headers,
            body: request.body is Map ? jsonEncode(request.body) : request.body,
          );
          break;
        case 'DELETE':
          response = await client.delete(uri, headers: request.headers);
          break;
        default:
          return OperationResult.success(request.id, false, error: 'Unsupported method: ${request.method}');
      }

      client.close();

      final success = response.statusCode >= 200 && response.statusCode < 300;
      return OperationResult.success(
        request.id,
        success,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } catch (e) {
      return OperationResult.success(request.id, false, error: e.toString());
    }
  }

  void _scheduleRetry(QueuedRequest request) {
    if (request.retryCount < config.maxRetryAttempts) {
      final delay = config.retryDelay * request.retryCount + const Duration(seconds: 1);
      Future.delayed(delay, () {
        final updateRequest = request.withRetry();
        final index = _requestQueue.indexWhere((r) => r.id == request.id);
        if (index != -1) {
          _requestQueue[index] = updateRequest;
          _saveQueueToStorage();
        }
      });
    }
  }

  Future<void> _loadQueueFromStorage() async {
    if (kIsWeb) return; // Pas de stockage fichier sur web

    try {
      final file = File(_queueFile);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> queueData = jsonDecode(content);

        _requestQueue.clear();
        _requestQueue.addAll(
          queueData.map((item) => QueuedRequest.fromJson(item)).toList()
        );

        print('📋 Loaded ${_requestQueue.length} queued operations');
      }
    } catch (e) {
      print('❌ Failed to load queue: $e');
    }
  }

  Future<void> _saveQueueToStorage() async {
    if (kIsWeb) return;

    try {
      final queueData = _requestQueue.map((r) => r.toJson()).toList();
      final file = File(_queueFile);
      await file.writeAsString(jsonEncode(queueData));
    } catch (e) {
      print('❌ Failed to save queue: $e');
    }
  }

  Future<void> _loadFailedOperationsFromStorage() async {
    if (kIsWeb) return;

    try {
      final file = File(_failedOpsFile);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> failedData = jsonDecode(content);

        _failedOperations.clear();
        _failedOperations.addAll(
          failedData.map((item) => QueuedRequest.fromJson(item)).toList()
        );
      }
    } catch (e) {
      print('❌ Failed to load failed operations: $e');
    }
  }

  Future<void> _saveFailedOperationsToStorage() async {
    if (kIsWeb) return;

    try {
      final failedData = _failedOperations.map((r) => r.toJson()).toList();
      final file = File(_failedOpsFile);
      await file.writeAsString(jsonEncode(failedData));
    } catch (e) {
      print('❌ Failed to save failed operations: $e');
    }
  }

  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${_requestQueue.length}';
  }
}

/// Résultat d'une opération synchronisée
class OperationResult {
  final String requestId;
  final bool success;
  final int? statusCode;
  final String? responseBody;
  final String? error;

  OperationResult.success(
    this.requestId,
    this.success, {
    this.statusCode,
    this.responseBody,
    this.error,
  });

  @override
  String toString() {
    return 'OperationResult(requestId: $requestId, success: $success, statusCode: $statusCode)';
  }
}

/// Résultat de la synchronisation complète
class SyncResult {
  final SyncStatus status;
  final int syncedCount;
  final int failedCount;
  final List<OperationResult>? results;
  final String? message;

  const SyncResult({
    required this.status,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.results,
    this.message,
  });

  bool get hasErrors => failedCount > 0;
  bool get isComplete => failedCount == 0;
}
