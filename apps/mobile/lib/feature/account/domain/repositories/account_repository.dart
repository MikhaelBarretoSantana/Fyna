import 'package:fyna/feature/account/domain/entities/account_entity.dart';

/// Contrato do repositório de contas.
abstract class AccountRepository {
  /// Lista todas as contas do usuário autenticado.
  Future<List<AccountEntity>> getAccounts();

  /// Busca uma conta pelo ID.
  Future<AccountEntity> getAccount(String id);

  /// Cria uma nova conta.
  Future<AccountEntity> createAccount({
    required String name,
    required String type,
    String? institution,
    String? color,
    String? icon,
    double? initialBalance,
    bool? includeInTotal,
  });

  /// Atualiza uma conta existente.
  Future<AccountEntity> updateAccount({
    required String id,
    String? name,
    String? type,
    String? institution,
    String? color,
    String? icon,
    double? currentBalance,
    bool? isActive,
    bool? includeInTotal,
  });

  /// Exclui uma conta.
  Future<void> deleteAccount(String id);
}
