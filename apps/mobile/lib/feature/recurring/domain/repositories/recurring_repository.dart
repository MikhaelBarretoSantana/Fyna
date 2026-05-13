import 'package:fyna/feature/recurring/domain/entities/recurring_transaction_entity.dart';

/// Contrato do repositório de transações recorrentes.
abstract class RecurringRepository {
  Future<List<RecurringTransactionEntity>> getActiveRecurring();
  Future<List<RecurringTransactionEntity>> getAllRecurring();
  Future<RecurringTransactionEntity> getRecurring(String id);

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
  });

  Future<RecurringTransactionEntity> updateRecurring({
    required String id,
    String? categoryId,
    double? amount,
    String? description,
    DateTime? endDate,
    bool? isActive,
  });

  Future<void> deleteRecurring(String id);
}