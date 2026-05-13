import 'package:dio/dio.dart';
import 'package:fyna/config/env/app_env.dart';
import 'package:fyna/core/network/auth_interceptor.dart';
import 'package:fyna/core/network/token_storage.dart';

/// Singleton-factory do Dio já configurado.
class DioClient {
  late final Dio dio;

  DioClient({required TokenStorage tokenStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppEnv.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppEnv.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage: tokenStorage, dio: dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
    ]);
  }
}
