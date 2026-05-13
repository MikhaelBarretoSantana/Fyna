/// Tipos de transação — espelha `TransactionsType` do backend.
enum TransactionType {
  income,
  expense,
  transfer;

  /// Converte string JSON (UPPER_SNAKE_CASE) para enum.
  static TransactionType fromJson(String value) {
    switch (value) {
      case 'INCOME':
        return TransactionType.income;
      case 'EXPENSE':
        return TransactionType.expense;
      case 'TRANSFER':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  /// Converte para string JSON (UPPER_SNAKE_CASE).
  String toJson() {
    switch (this) {
      case TransactionType.income:
        return 'INCOME';
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.transfer:
        return 'TRANSFER';
    }
  }

  /// Label para exibição.
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Receita';
      case TransactionType.expense:
        return 'Despesa';
      case TransactionType.transfer:
        return 'Transferência';
    }
  }
}
