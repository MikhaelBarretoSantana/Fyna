import 'package:fyna/core/enums/transaction_type.dart';

/// Entidade de domínio de transação — espelha `TransactionResponse` do backend.
///
/// Nota sobre datas:
/// - [transactionDate] é a **data civil** do lançamento (LocalDate no backend).
///   Sempre vem com hora 00:00 — não use para exibir hora.
/// - [createdAt] é o **momento exato** em que o registro foi criado no banco
///   (TIMESTAMP com timezone). Usado pela UI para mostrar hora do lançamento.
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
  final DateTime? createdAt;

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
    this.createdAt,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : null,
    );
  }

  /// Datetime efetivo para exibição na UI.
  ///
  /// Combina a data civil ([transactionDate]) com a hora derivada de
  /// [createdAt] quando ambos caem no mesmo dia — assim o usuário vê
  /// "Hoje, 19:42" em vez de "Hoje, 00:00".
  ///
  /// Para entradas históricas backdatadas (`transactionDate` ≠ data de
  /// `createdAt`), usa apenas a data civil com hora 00:00 (o backend não
  /// armazena a hora real do evento).
  DateTime get displayDateTime {
    if (createdAt == null) return transactionDate;
    final txDay = DateTime(
        transactionDate.year, transactionDate.month, transactionDate.day);
    final createdDay =
        DateTime(createdAt!.year, createdAt!.month, createdAt!.day);
    if (txDay == createdDay) {
      return DateTime(
        transactionDate.year,
        transactionDate.month,
        transactionDate.day,
        createdAt!.hour,
        createdAt!.minute,
        createdAt!.second,
      );
    }
    return transactionDate;
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
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
