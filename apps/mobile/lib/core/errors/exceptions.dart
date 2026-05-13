/// Exceção lançada quando a API retorna um erro.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Exceção de rede / conexão.
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Sem conexão com a internet'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exceção de timeout.
class TimeoutException implements Exception {
  final String message;

  const TimeoutException(
      {this.message = 'A requisição demorou demais. Tente novamente.'});

  @override
  String toString() => 'TimeoutException: $message';
}
