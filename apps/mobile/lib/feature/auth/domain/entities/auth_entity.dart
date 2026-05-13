import 'package:fyna/feature/auth/domain/entities/user_entity.dart';

/// Entidade de domínio da resposta de autenticação.
///
/// Espelha o `AuthResponse` do backend:
/// ```json
/// {
///   "accessToken": "...",
///   "refreshToken": "...",
///   "tokenType": "Bearer",
///   "user": { "id": 1, "login": "...", "email": "...", "fullName": "..." }
/// }
/// ```
class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserEntity user;

  const AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthEntity.fromJson(Map<String, dynamic> json) {
    return AuthEntity(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
