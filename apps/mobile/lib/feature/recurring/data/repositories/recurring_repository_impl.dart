import 'package:fyna/feature/recurring/data/datasource/recurring_remote_datasource.dart';
import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';
import 'package:fyna/feature/recurring/domain/repositories/recurring_repository.dart';

/// Implementação concreta do [RecurringRepository].
class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringRemoteDatasource _datasource;

  RecurringRepositoryImpl({required RecurringRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<List<RecurringTransactionEntity>> getActiveRecurring() {
    return _datasource.getActiveRecurring();
  }

  @override
  Future<List<RecurringTransactionEntity>> getAllRecurring() {
    return _datasource.getAllRecurring();
  }

  @override
  Future<RecurringTransactionEntity> getRecurring(String id) {
    return _datasource.getRecurring(id);
  }

  @override
  Future<RecurringTransactionEntity> createRecurring({
    required String accountId,
    required String type,
    required double amount,
    required String description,
    required String frequency,
    required DateTime startDate,
    String? categoryId,
    int? frequencyInterval,
    DateTime? endDate,
  }) {
    final body = <String, dynamic>{
      'accountId': accountId,
      'type': type,
      'amount': amount,
      'description': description,
      'frequency': frequency,
      'startDate': _formatDate(startDate),
      if (categoryId != null) 'categoryId': categoryId,
      if (frequencyInterval != null) 'frequencyInterval': frequencyInterval,
      if (endDate != null) 'endDate': _formatDate(endDate),
    };
    return _datasource.createRecurring(body);
  }

  @override
  Future<RecurringTransactionEntity> updateRecurring({
    required String id,
    String? categoryId,
    double? amount,
    String? description,
    DateTime? endDate,
    bool? isActive,
  }) {
    final body = <String, dynamic>{
      if (categoryId != null) 'categoryId': categoryId,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (endDate != null) 'endDate': _formatDate(endDate),
      if (isActive != null) 'isActive': isActive,
    };
    return _datasource.updateRecurring(id, body);
  }

  @override
  Future<void> deleteRecurring(String id) {
    return _datasource.deleteRecurring(id);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}