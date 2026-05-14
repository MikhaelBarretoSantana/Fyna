import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

abstract class AppEnv {
  /// URL do ngrok para testes em dispositivo físico.
  /// Domínio estático reservado — não muda entre restarts do `docker compose up`.
  /// Deixe null para usar localhost/emulador.
  static const String? _ngrokUrl = 'https://glutinous-reforest-grape.ngrok-free.dev';

  static const String _basePath = '/api/v1';

  static String get apiBaseUrl {
    // Dispositivo físico (Android/iOS real) usa ngrok se configurado
    if (!kIsWeb && _ngrokUrl != null) {
      final isPhysicalDevice = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      if (isPhysicalDevice) {
        return '$_ngrokUrl$_basePath';
      }
    }

    const port = '8080';

    if (kIsWeb) {
      return 'http://localhost:$port$_basePath';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulador Android usa 10.0.2.2 para acessar o host
      return 'http://10.0.2.2:$port$_basePath';
    }

    return 'http://localhost:$port$_basePath';
  }

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  /// URL do WebSocket (STOMP). Mantém o mesmo host do REST mas troca o esquema
  /// para ws/wss e aponta para o endpoint `/ws` na raiz (sem `/api/v1`).
  static String get wsUrl {
    final ngrok = _ngrokUrl;
    if (!kIsWeb && ngrok != null) {
      final isPhysicalDevice =
          defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS;
      if (isPhysicalDevice) {
        final wsHost = ngrok
            .replaceFirst('https://', 'wss://')
            .replaceFirst('http://', 'ws://');
        return '$wsHost/ws';
      }
    }

    const port = '8080';

    if (kIsWeb) {
      return 'ws://localhost:$port/ws';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:$port/ws';
    }

    return 'ws://localhost:$port/ws';
  }
}
