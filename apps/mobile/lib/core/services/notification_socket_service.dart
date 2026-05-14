import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fyna/config/env/app_env.dart';
import 'package:fyna/core/network/token_storage.dart';
import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Mantém uma conexão STOMP/WebSocket com o backend e expõe um stream de
/// notificações em tempo real. O cliente recebe eventos em
/// `/user/queue/notifications` — Spring resolve por Principal vinculado ao
/// JWT enviado no frame CONNECT.
///
/// A conexão é resiliente: o próprio stomp_dart_client reconecta em caso de
/// queda, e o service só tenta conectar quando há accessToken disponível.
class NotificationSocketService {
  final TokenStorage _tokenStorage;

  StompClient? _client;
  final _controller = StreamController<NotificationEntity>.broadcast();

  NotificationSocketService({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  /// Stream consumido pelas telas (badge na home, lista de notificações).
  Stream<NotificationEntity> get notifications => _controller.stream;

  bool get isConnected => _client?.connected ?? false;

  /// Conecta (ou reconecta) ao backend. Idempotente: se já estiver ativo,
  /// fecha e reabre — útil após login com novo token.
  void connect() {
    final token = _tokenStorage.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint('[WS] Sem accessToken — não conectando');
      return;
    }

    disconnect();

    final client = StompClient(
      config: StompConfig(
        url: AppEnv.wsUrl,
        onConnect: _onConnect,
        onDisconnect: (_) => debugPrint('[WS] Desconectado'),
        onWebSocketError: (e) => debugPrint('[WS] Erro: $e'),
        onStompError: (frame) =>
            debugPrint('[WS] STOMP error: ${frame.body}'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    client.activate();
    _client = client;
  }

  /// Encerra a conexão. Chamar no logout.
  void disconnect() {
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
  }

  void _onConnect(StompFrame _) {
    debugPrint('[WS] Conectado — assinando /user/queue/notifications');
    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final entity = NotificationEntity.fromJson(json);
          _controller.add(entity);
        } catch (e) {
          debugPrint('[WS] Falha ao parsear frame: $e');
        }
      },
    );
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
