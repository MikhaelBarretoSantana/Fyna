import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Datasource para registrar/desregistrar tokens FCM no backend.
class FcmRemoteDatasource {
  final Dio _dio;

  FcmRemoteDatasource(this._dio);

  /// POST /api/v1/fcm/register
  Future<void> registerToken({
    required String token,
    String? deviceType,
    String? deviceId,
  }) async {
    try {
      await _dio.post('/fcm/register', data: {
        'token': token,
        if (deviceType != null) 'deviceType': deviceType,
        if (deviceId != null) 'deviceId': deviceId,
      });
    } catch (e) {
      // Falha silenciosa — não bloqueia o fluxo do app
      debugPrint('[FCM] Falha ao registrar token: $e');
    }
  }

  /// DELETE /api/v1/fcm/{token}
  Future<void> unregisterToken(String token) async {
    try {
      await _dio.delete('/fcm/$token');
    } catch (e) {
      debugPrint('[FCM] Falha ao remover token: $e');
    }
  }
}
