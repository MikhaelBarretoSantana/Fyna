import 'package:fyna/core/network/page_response_model.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';

/// Contrato do repositório de transações.
abstract class TransactionRepository {
  /// Lista transações do usuário com paginação.
  Future<PageResponseModel<TransactionEntity>> getTransactions({
    int page = 0,
    int size = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
  });

  /// Busca uma transação pelo ID.
  Future<TransactionEntity> getTransaction(String id);

  /// Cria uma nova transação.
  Future<TransactionEntity> createTransaction({
    required String accountId,
    required String type,
    required double amount,
    required String description,
    required DateTime transactionDate,
    String? categoryId,
    String? notes,
    DateTime? dueDate,
    bool? isPaid,
    String? attachmentUrl,
    String? transferAccountId,
  });

  /// Atualiza uma transação existente.
  Future<TransactionEntity> updateTransaction({
    required String id,
    String? categoryId,
    double? amount,
    String? description,
    String? notes,
    DateTime? transactionDate,
    DateTime? dueDate,
    bool? isPaid,
    String? attachmentUrl,
  });

  /// Exclui uma transação.
  Future<void> deleteTransaction(String id);
}
