import 'package:fyna/core/enums/recurring_frequency.dart';
import 'package:fyna/core/enums/transaction_type.dart';

/// Entidade de transação recorrente — espelha `RecurringTransactionResponse`.
class RecurringTransactionEntity {
  final String id;
  final String accountId;
  final String? categoryId;
  final String? categoryName;
  final TransactionType type;
  final double amount;
  final String description;
  final RecurringFrequency frequency;
  final int? frequencyInterval;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextOccurrence;
  final DateTime? lastGenerated;
  final bool isActive;

  const RecurringTransactionEntity({
    required this.id,
    required this.accountId,
    this.categoryId,
    this.categoryName,
    required this.type,
    required this.amount,
    required this.description,
    required this.frequency,
    this.frequencyInterval,
    required this.startDate,
    this.endDate,
    this.nextOccurrence,
    this.lastGenerated,
    this.isActive = true,
  });

  factory RecurringTransactionEntity.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionEntity(
      id: json['id'].toString(),
      accountId: json['accountId'].toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'] as String?,
      type: TransactionType.fromJson(json['type'] as String? ?? 'EXPENSE'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      frequency: RecurringFrequency.fromJson(
          json['frequency'] as String? ?? 'MONTHLY'),
      frequencyInterval: json['frequencyInterval'] as int? ?? 1,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      nextOccurrence: json['nextOccurrence'] != null
          ? DateTime.parse(json['nextOccurrence'] as String)
          : null,
      lastGenerated: json['lastGenerated'] != null
          ? DateTime.parse(json['lastGenerated'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type.toJson(),
      'amount': amount,
      'description': description,
      'frequency': frequency.toJson(),
      'frequencyInterval': frequencyInterval,
      'startDate': _formatDate(startDate),
      'endDate': endDate != null ? _formatDate(endDate!) : null,
      'nextOccurrence':
          nextOccurrence != null ? _formatDate(nextOccurrence!) : null,
      'lastGenerated':
          lastGenerated != null ? _formatDate(lastGenerated!) : null,
      'isActive': isActive,
    };
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}