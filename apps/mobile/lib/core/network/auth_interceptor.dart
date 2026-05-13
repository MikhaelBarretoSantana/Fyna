import 'package:dio/dio.dart';
import 'package:fyna/core/network/token_storage.dart';

/// Interceptor que anexa o Bearer token e faz refresh automático ao receber 401.
class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;

  // Evita loops infinitos de refresh
  bool _isRefreshing = false;

  static const _publicPaths = ['/auth/register', '/auth/login', '/auth/refresh'];

  AuthInterceptor({required this.tokenStorage, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = _publicPaths.any((p) => options.path.contains(p));

    if (!isPublic) {
      final token = tokenStorage.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final path = err.requestOptions.path;
    final isPublicPath = _publicPaths.any((p) => path.contains(p));

    if (response?.statusCode == 401 && !isPublicPath && !_isRefreshing) {
      final refreshToken = tokenStorage.refreshToken;

      if (refreshToken == null) {
        await _clearAndReject(err, handler);
        return;
      }

      _isRefreshing = true;

      try {
        final refreshResponse = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final data = refreshResponse.data is Map
            ? refreshResponse.data as Map<String, dynamic>
            : (refreshResponse.data['data'] as Map<String, dynamic>);

        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;

        if (newAccess == null) {
          await _clearAndReject(err, handler);
          return;
        }

        await tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh ?? refreshToken,
        );

        // Retry original request with new token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';

        final retried = await dio.fetch(retryOptions);
        handler.resolve(retried);
      } catch (_) {
        await _clearAndReject(err, handler);
      } finally {
        _isRefreshing = false;
      }
      return;
    }

    handler.next(err);
  }

  Future<void> _clearAndReject(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await tokenStorage.clearTokens();
    handler.next(err);
  }
}
