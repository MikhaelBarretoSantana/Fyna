import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fyna/feature/notifications/data/datasource/fcm_remote_datasource.dart';

/// Handler de mensagens recebidas em background — DEVE ser top-level.
/// O sistema isola este isolate, então não há acesso ao estado do app aqui;
/// apenas reage à mensagem (ex.: salvar localmente). Hoje só logamos.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][bg] ${message.messageId} — ${message.notification?.title}');
}

/// Gerencia o ciclo de vida do token FCM e a entrega de mensagens.
///
/// Tolerante a falhas de configuração: se o Firebase não estiver inicializado
/// corretamente (sem google-services.json / GoogleService-Info.plist), o
/// service desabilita push silenciosamente — o resto do app segue normal.
class FcmService {
  final FcmRemoteDatasource _datasource;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = false;
  String? _currentToken;

  FcmService({required FcmRemoteDatasource datasource})
      : _datasource = datasource;

  bool get isEnabled => _enabled;

  /// Inicializa Firebase, configura listeners e canal Android.
  /// Idempotente: chamadas extras são no-op.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[FCM] Firebase indisponível — push desabilitado: $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      await _setupLocalNotifications();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
      _enabled = true;
    } catch (e) {
      debugPrint('[FCM] Falha ao configurar listeners: $e');
    }
  }

  /// Solicita permissão (iOS/Android 13+) e registra o token no backend.
  /// Chamar após login bem-sucedido.
  Future<void> requestPermissionAndRegister() async {
    if (!_enabled) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permissão negada');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _currentToken = token;
      await _datasource.registerToken(
        token: token,
        deviceType: _detectDeviceType(),
      );
      debugPrint('[FCM] Token registrado: ${_mask(token)}');
    } catch (e) {
      debugPrint('[FCM] Falha em requestPermissionAndRegister: $e');
    }
  }

  /// Remove o token atual do backend e do Firebase. Chamar no logout.
  Future<void> unregister() async {
    if (!_enabled) return;
    final token = _currentToken;
    try {
      if (token != null) {
        await _datasource.unregisterToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[FCM] Falha em unregister: $e');
    } finally {
      _currentToken = null;
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Canal Android — necessário para que a notif seja mostrada em foreground
    const channel = AndroidNotificationChannel(
      'fyna_default',
      'Fyna',
      description: 'Notificações do Fyna',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fyna_default',
          'Fyna',
          channelDescription: 'Notificações do Fyna',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _onTokenRefresh(String token) async {
    _currentToken = token;
    await _datasource.registerToken(
      token: token,
      deviceType: _detectDeviceType(),
    );
    debugPrint('[FCM] Token atualizado: ${_mask(token)}');
  }

  String? _detectDeviceType() {
    if (kIsWeb) return 'WEB';
    try {
      if (Platform.isAndroid) return 'ANDROID';
      if (Platform.isIOS) return 'IOS';
    } catch (_) {}
    return null;
  }

  String _mask(String token) =>
      token.length <= 8 ? '***' : '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}
