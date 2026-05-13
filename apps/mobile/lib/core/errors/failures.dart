/// Classe base para falhas tratadas na camada de domínio.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Falha vinda do servidor (ex: 400, 409, 500).
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// Falha de rede (sem internet).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet']);
}

/// Falha de timeout.
class TimeoutFailure extends Failure {
  const TimeoutFailure(
      [super.message = 'A requisição demorou demais. Tente novamente.']);
}
