/// Entidade de domínio do usuário autenticado.
class UserEntity {
  final String id;
  final String login;
  final String email;
  final String fullName;

  const UserEntity({
    required this.id,
    required this.login,
    required this.email,
    required this.fullName,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'].toString(),
      login: json['login'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
    );
  }
}
