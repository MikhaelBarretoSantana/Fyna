import 'package:fyna/feature/auth/domain/entities/auth_entity.dart';

/// Contrato do repositório de autenticação.
abstract class AuthRepository {
  /// Registra um novo usuário.
  Future<AuthEntity> register({
    required String login,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    DateTime? birthDate,
  });

  /// Autentica um usuário existente.
  Future<AuthEntity> login({
    required String login,
    required String password,
  });

  /// Renova a sessão usando o refresh token.
  /// Retorna a nova [AuthEntity] (com novos access/refresh tokens — rotação).
  Future<AuthEntity> refresh({required String refreshToken});

  /// Faz logout invalidando o token.
  Future<void> logout();
}
