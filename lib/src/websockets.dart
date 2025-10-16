// **************************************************************************
// Flugx GetX API Generator - WebSocket Support
// **************************************************************************

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'auth_manager.dart';

/// État de connexion WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Configuration WebSocket
class WebSocketConfig {
  final String url;
  final Map<String, String>? headers;
  final Duration reconnectInterval;
  final int maxReconnectAttempts;
  final Duration pingInterval;
  final Duration connectionTimeout;
  final bool enableAutoReconnect;
  final bool enableHeartbeat;
  final AuthConfig? authConfig;
  final Map<String, dynamic>? initialParams;

  const WebSocketConfig({
    required this.url,
    this.headers,
    this.reconnectInterval = const Duration(seconds: 5),
    this.maxReconnectAttempts = 5,
    this.pingInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
    this.enableAutoReconnect = true,
    this.enableHeartbeat = true,
    this.authConfig,
    this.initialParams,
  });
}

/// Message WebSocket
class WebSocketMessage {
  final String? event;
  final dynamic data;
  final DateTime timestamp;
  final bool isBinary;
  final String? correlationId;

  WebSocketMessage({
    this.event,
    this.data,
    DateTime? timestamp,
    this.isBinary = false,
    this.correlationId,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Crée un message à partir de données JSON
  factory WebSocketMessage.fromJson(Map<String, dynamic> json, {String? correlationId}) {
    return WebSocketMessage(
      event: json['event'] as String?,
      data: json['data'],
      correlationId: correlationId ?? json['correlation_id'] as String?,
    );
  }

  /// Convertit le message en JSON
  Map<String, dynamic> toJson() {
    return {
      if (event != null) 'event': event,
      if (data != null) 'data': data,
      'timestamp': timestamp.toIso8601String(),
      if (correlationId != null) 'correlation_id': correlationId,
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage(event: $event, data: $data, timestamp: $timestamp)';
  }
}

/// Gestionnaire d'événements WebSocket
class WebSocketEventHandler {
  final Map<String, List<VoidCallback>> _eventListeners = {};
  final Map<String, List<void Function(WebSocketMessage)>> _typedEventListeners = {};

  /// Ajoute un listener pour un événement
  void addEventListener(String event, VoidCallback listener) {
    _eventListeners.putIfAbsent(event, () => []).add(listener);
  }

  /// Ajoute un listener typé pour un événement avec message
  void addTypedEventListener(String event, void Function(WebSocketMessage) listener) {
    _typedEventListeners.putIfAbsent(event, () => []).add(listener);
  }

  /// Supprime un listener
  void removeEventListener(String event, VoidCallback listener) {
    _eventListeners[event]?.remove(listener);
  }

  /// Supprime un listener typé
  void removeTypedEventListener(String event, void Function(WebSocketMessage) listener) {
    _typedEventListeners[event]?.remove(listener);
  }

  /// Déclenche un événement
  void emitEvent(String event, [WebSocketMessage? message]) {
    final listeners = _eventListeners[event];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(message);
        } catch (e) {
          print('Error in WebSocket event listener: $e');
        }
      }
    }

    final typedListeners = _typedEventListeners[event];
    if (typedListeners != null && message != null) {
      for (final listener in typedListeners) {
        try {
          listener(message);
        } catch (e) {
          print('Error in WebSocket typed event listener: $e');
        }
      }
    }
  }

  /// Vide tous les listeners
  void clearListeners() {
    _eventListeners.clear();
    _typedEventListeners.clear();
  }
}

/// Client WebSocket avec gestion automatique de reconnexion
class WebSocketClient {
  final WebSocketConfig config;
  WebSocket? _socket;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _connectionTimer;
  int _reconnectAttempts = 0;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  final WebSocketEventHandler eventHandler = WebSocketEventHandler();
  final StreamController<WebSocketConnectionState> _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();

  WebSocketClient(this.config);

  /// Stream de l'état de connexion
  Stream<WebSocketConnectionState> get connectionState => _connectionStateController.stream;

  /// Stream des messages reçus
  Stream<WebSocketMessage> get messages => _messageController.stream;

  /// État actuel de connexion
  WebSocketConnectionState get state => _state;

  /// Établit la connexion
  Future<void> connect() async {
    if (_state == WebSocketConnectionState.connecting) return;

    _setState(WebSocketConnectionState.connecting);
    _reconnectAttempts = 0;

    try {
      await _establishConnection();
    } catch (e) {
      _handleConnectionError(e);
      if (config.enableAutoReconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// Déconnecte proprement
  Future<void> disconnect() async {
    _cancelTimers();
    _setState(WebSocketConnectionState.disconnected);

    await _subscription?.cancel();
    await _socket?.close();
    _socket = null;

    eventHandler.clearListeners();
  }

  /// Envoie un message
  Future<void> send(WebSocketMessage message) async {
    if (_socket == null || _state != WebSocketConnectionState.connected) {
      throw WebSocketException('WebSocket is not connected');
    }

    try {
      final jsonData = jsonEncode(message.toJson());
      _socket!.add(jsonData);
      eventHandler.emitEvent('message_sent', message);
    } catch (e) {
      _handleSendError(e);
      rethrow;
    }
  }

  /// Envoie un message raw
  Future<void> sendRaw(dynamic data) async {
    if (_socket == null || _state != WebSocketConnectionState.connected) {
      throw WebSocketException('WebSocket is not connected');
    }

    _socket!.add(data);
  }

  /// S'abonne à un événement
  void on(String event, VoidCallback listener) {
    eventHandler.addEventListener(event, listener);
  }

  /// S'abonne à un événement typé
  void onMessage(String event, void Function(WebSocketMessage) listener) {
    eventHandler.addTypedEventListener(event, listener);
  }

  /// Se désabonne d'un événement
  void off(String event, VoidCallback listener) {
    eventHandler.removeEventListener(event, listener);
  }

  /// Se désabonne d'un événement typé
  void offMessage(String event, void Function(WebSocketMessage) listener) {
    eventHandler.removeTypedEventListener(event, listener);
  }

  Future<void> _establishConnection() async {
    final authManager = config.authConfig != null
        ? SimpleAuthManager(config.authConfig!)
        : null;

    final authHeaders = authManager != null
        ? await authManager.getAuthHeaders()
        : <String, String>{};

    final headers = {
      ...?config.headers,
      ...authHeaders,
    };

    // Construction de l'URL avec paramètres
    final uri = Uri.parse(config.url);
    final wsUri = Uri(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      host: uri.host,
      port: uri.port,
      path: uri.path,
      queryParameters: {
        ...uri.queryParameters,
        ...?config.initialParams,
      },
    );

    // Timeout de connexion
    _connectionTimer?.cancel();
    _connectionTimer = Timer(config.connectionTimeout, () {
      throw TimeoutException('WebSocket connection timeout');
    });

    _socket = await WebSocket.connect(
      wsUri.toString(),
      headers: headers,
    );

    _connectionTimer?.cancel();

    _setState(WebSocketConnectionState.connected);
    _reconnectAttempts = 0;

    // Démarre le heartbeat si activé
    if (config.enableHeartbeat) {
      _startHeartbeat();
    }

    // Configure les listeners
    _subscription = _socket!.listen(
      _onMessage,
      onDone: _onConnectionClosed,
      onError: _onConnectionError,
      cancelOnError: false,
    );

    eventHandler.emitEvent('connected');

    // Envoie un message d'identification si spécifié
    if (config.initialParams?.isNotEmpty == true) {
      final identifyMessage = WebSocketMessage(
        event: 'identify',
        data: config.initialParams,
      );
      await send(identifyMessage);
    }
  }

  void _onMessage(dynamic data) {
    try {
      WebSocketMessage? message;

      if (data is String) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        message = WebSocketMessage.fromJson(jsonData);
      } else {
        // Message binaire
        message = WebSocketMessage(data: data, isBinary: true);
      }

      _messageController.add(message);

      // Émet l'événement spécifique
      if (message.event != null) {
        eventHandler.emitEvent(message.event!, message);
      }

    } catch (e) {
      print('Error parsing WebSocket message: $e');
      eventHandler.emitEvent('parse_error', WebSocketMessage(data: {'error': e.toString()}));
    }
  }

  void _onConnectionClosed() {
    _cancelTimers();
    eventHandler.emitEvent('disconnected');

    if (_state != WebSocketConnectionState.disconnected) {
      _setState(WebSocketConnectionState.disconnected);

      if (config.enableAutoReconnect && _reconnectAttempts < config.maxReconnectAttempts) {
        _scheduleReconnect();
      }
    }
  }

  void _onConnectionError(Object error) {
    _handleConnectionError(error);
  }

  void _handleConnectionError(Object error) {
    print('WebSocket connection error: $error');
    _setState(WebSocketConnectionState.failed);
    eventHandler.emitEvent('connection_error', WebSocketMessage(data: {'error': error.toString()}));
  }

  void _handleSendError(Object error) {
    print('WebSocket send error: $error');
    eventHandler.emitEvent('send_error', WebSocketMessage(data: {'error': error.toString()}));
  }

  void _setState(WebSocketConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _connectionStateController.add(newState);
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null || _reconnectAttempts >= config.maxReconnectAttempts) return;

    _reconnectAttempts++;
    _setState(WebSocketConnectionState.reconnecting);

    print('Scheduling WebSocket reconnect in ${config.reconnectInterval.inSeconds}s (attempt $_reconnectAttempts/${config.maxReconnectAttempts})');

    _reconnectTimer = Timer(config.reconnectInterval, () async {
      _reconnectTimer = null;
      try {
        await _establishConnection();
      } catch (e) {
        if (_reconnectAttempts < config.maxReconnectAttempts) {
          _scheduleReconnect();
        } else {
          _setState(WebSocketConnectionState.failed);
          eventHandler.emitEvent('max_reconnect_attempts_reached');
        }
      }
    });
  }

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(config.pingInterval, (_) {
      if (_state == WebSocketConnectionState.connected) {
        try {
          _socket!.add('ping');
        } catch (e) {
          print('Heartbeat failed: $e');
        }
      }
    });
  }

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  /// Vérifie si la connexion est active
  bool get isConnected => _state == WebSocketConnectionState.connected;

  /// Force une reconnexion
  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  /// Libère les ressources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
  }
}

/// Gestionnaire de canaux WebSocket (room/channels)
class WebSocketChannel {
  final WebSocketClient client;
  final String channelName;
  final Map<String, dynamic> channelData;

  WebSocketChannel({
    required this.client,
    required this.channelName,
    this.channelData = const {},
  });

  /// Rejoint le canal
  Future<void> join() async {
    final joinMessage = WebSocketMessage(
      event: 'join_channel',
      data: {
        'channel': channelName,
        ...channelData,
      },
    );
    await client.send(joinMessage);
  }

  /// Quitte le canal
  Future<void> leave() async {
    final leaveMessage = WebSocketMessage(
      event: 'leave_channel',
      data: {'channel': channelName},
    );
    await client.send(leaveMessage);
  }

  /// Envoie un message dans le canal
  Future<void> send(String event, dynamic data) async {
    final message = WebSocketMessage(
      event: 'channel_message',
      data: {
        'channel': channelName,
        'event': event,
        'data': data,
      },
    );
    await client.send(message);
  }
}

typedef VoidCallback<T> = void Function(T);
