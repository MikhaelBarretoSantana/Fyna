import 'package:fyna/feature/account/data/datasource/account_remote_datasource.dart';
import 'package:fyna/feature/account/domain/entities/account_entity.dart';
import 'package:fyna/feature/account/domain/repositories/account_repository.dart';

/// Implementação concreta do [AccountRepository].
class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDatasource _datasource;

  AccountRepositoryImpl({required AccountRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<AccountEntity>> getAccounts() {
    return _datasource.getAccounts();
  }

  @override
  Future<AccountEntity> getAccount(String id) {
    return _datasource.getAccount(id);
  }

  @override
  Future<AccountEntity> createAccount({
    required String name,
    required String type,
    String? institution,
    String? color,
    String? icon,
    double? initialBalance,
    bool? includeInTotal,
  }) {
    final body = <String, dynamic>{
      'name': name,
      'type': type,
      if (institution != null) 'institution': institution,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (initialBalance != null) 'initialBalance': initialBalance,
      if (includeInTotal != null) 'includeInTotal': includeInTotal,
    };
    return _datasource.createAccount(body);
  }

  @override
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
  }) {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (institution != null) 'institution': institution,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (currentBalance != null) 'currentBalance': currentBalance,
      if (isActive != null) 'isActive': isActive,
      if (includeInTotal != null) 'includeInTotal': includeInTotal,
    };
    return _datasource.updateAccount(id, body);
  }

  @override
  Future<void> deleteAccount(String id) {
    return _datasource.deleteAccount(id);
  }
}
