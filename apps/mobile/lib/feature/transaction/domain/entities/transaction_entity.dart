import 'package:fyna/core/enums/transaction_type.dart';

/// Entidade de domínio de transação — espelha `TransactionResponse` do backend.
class TransactionEntity {
  final String id;
  final String? accountId;
  final String? categoryId;
  final String? categoryName;
  final String? transferPairId;
  final TransactionType type;
  final double amount;
  final String description;
  final String? notes;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final bool isPaid;
  final bool isRecurring;
  final String? recurringTransactionId;
  final String? attachmentUrl;

  const TransactionEntity({
    required this.id,
    this.accountId,
    this.categoryId,
    this.categoryName,
    this.transferPairId,
    required this.type,
    required this.amount,
    required this.description,
    this.notes,
    required this.transactionDate,
    this.dueDate,
    required this.isPaid,
    required this.isRecurring,
    this.recurringTransactionId,
    this.attachmentUrl,
  });

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'].toString(),
      accountId: json['accountId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'] as String?,
      transferPairId: json['transferPairId']?.toString(),
      type: TransactionType.fromJson(json['type'] as String? ?? 'EXPENSE'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String?,
      transactionDate: json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'] as String)
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringTransactionId: json['recurringTransactionId']?.toString(),
      attachmentUrl: json['attachmentUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'transferPairId': transferPairId,
      'type': type.toJson(),
      'amount': amount,
      'description': description,
      'notes': notes,
      'transactionDate':
          '${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
      'dueDate': dueDate != null
          ? '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'
          : null,
      'isPaid': isPaid,
      'isRecurring': isRecurring,
      'recurringTransactionId': recurringTransactionId,
      'attachmentUrl': attachmentUrl,
    };
  }
}
