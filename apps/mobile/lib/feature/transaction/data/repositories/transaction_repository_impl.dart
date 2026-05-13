import 'package:fyna/core/network/page_response_model.dart';
import 'package:fyna/feature/transaction/data/datasource/transaction_remote_datasource.dart';
import 'package:fyna/feature/transaction/domain/entities/transaction_entity.dart';
import 'package:fyna/feature/transaction/domain/repositories/transaction_repository.dart';

/// Implementação concreta do [TransactionRepository].
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDatasource _datasource;

  TransactionRepositoryImpl({required TransactionRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<PageResponseModel<TransactionEntity>> getTransactions({
    int page = 0,
    int size = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
  }) {
    return _datasource.getTransactions(
      page: page,
      size: size,
      startDate: startDate != null ? _formatDate(startDate) : null,
      endDate: endDate != null ? _formatDate(endDate) : null,
      accountId: accountId,
      categoryId: categoryId,
    );
  }

  @override
  Future<TransactionEntity> getTransaction(String id) {
    return _datasource.getTransaction(id);
  }

  @override
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
  }) {
    final body = <String, dynamic>{
      'accountId': accountId,
      'type': type,
      'amount': amount,
      'description': description,
      'transactionDate': _formatDate(transactionDate),
      if (categoryId != null) 'categoryId': categoryId,
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'dueDate': _formatDate(dueDate),
      if (isPaid != null) 'isPaid': isPaid,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (transferAccountId != null) 'transferAccountId': transferAccountId,
    };
    return _datasource.createTransaction(body);
  }

  @override
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
  }) {
    final body = <String, dynamic>{
      if (categoryId != null) 'categoryId': categoryId,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (transactionDate != null)
        'transactionDate': _formatDate(transactionDate),
      if (dueDate != null) 'dueDate': _formatDate(dueDate),
      if (isPaid != null) 'isPaid': isPaid,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    };
    return _datasource.updateTransaction(id, body);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _datasource.deleteTransaction(id);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
