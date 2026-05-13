import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:fyna/core/network/auth_interceptor.dart';
import 'package:fyna/core/network/token_storage.dart';

@GenerateMocks([TokenStorage, Dio])
import 'auth_interceptor_test.mocks.dart';

void main() {
  late MockTokenStorage tokenStorage;
  late MockDio dio;
  late AuthInterceptor interceptor;

  setUp(() {
    tokenStorage = MockTokenStorage();
    dio = MockDio();
    interceptor = AuthInterceptor(tokenStorage: tokenStorage, dio: dio);
  });

  group('onRequest', () {
    test('adiciona Authorization header em rota protegida', () {
      when(tokenStorage.accessToken).thenReturn('my-token');

      final options = RequestOptions(path: '/api/v1/transactions');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], equals('Bearer my-token'));
    });

    test('não adiciona header em rotas públicas', () {
      final publicPaths = ['/auth/register', '/auth/login', '/auth/refresh'];

      for (final path in publicPaths) {
        final options = RequestOptions(path: path);
        final handler = RequestInterceptorHandler();
        interceptor.onRequest(options, handler);
        expect(options.headers.containsKey('Authorization'), isFalse,
            reason: 'Não deve adicionar header em $path');
      }
    });

    test('não adiciona header quando token é null', () {
      when(tokenStorage.accessToken).thenReturn(null);

      final options = RequestOptions(path: '/api/v1/accounts');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('onError — refresh de token', () {
    test('limpa tokens e rejeita quando refreshToken é null e status é 401', () async {
      when(tokenStorage.refreshToken).thenReturn(null);
      when(tokenStorage.clearTokens()).thenAnswer((_) async {});

      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v1/accounts'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/accounts'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = ErrorInterceptorHandler();

      await interceptor.onError(err, handler);

      verify(tokenStorage.clearTokens()).called(1);
    });

    test('não tenta refresh em rotas públicas com 401', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = ErrorInterceptorHandler();

      await interceptor.onError(err, handler);

      verifyNever(tokenStorage.refreshToken);
    });

    test('não tenta refresh quando status não é 401', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v1/accounts'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/accounts'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = ErrorInterceptorHandler();

      await interceptor.onError(err, handler);

      verifyNever(tokenStorage.refreshToken);
    });
  });
}
