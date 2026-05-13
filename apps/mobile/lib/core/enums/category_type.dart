/// Tipos de categoria — espelha `CategoriesTypes` do backend.
enum CategoryType {
  income,
  expense,
  transfer;

  /// Converte string JSON (UPPER_SNAKE_CASE) para enum.
  static CategoryType fromJson(String value) {
    switch (value) {
      case 'INCOME':
        return CategoryType.income;
      case 'EXPENSE':
        return CategoryType.expense;
      case 'TRANSFER':
        return CategoryType.transfer;
      default:
        return CategoryType.expense;
    }
  }

  /// Converte para string JSON (UPPER_SNAKE_CASE).
  String toJson() {
    switch (this) {
      case CategoryType.income:
        return 'INCOME';
      case CategoryType.expense:
        return 'EXPENSE';
      case CategoryType.transfer:
        return 'TRANSFER';
    }
  }

  /// Label para exibição.
  String get label {
    switch (this) {
      case CategoryType.income:
        return 'Receita';
      case CategoryType.expense:
        return 'Despesa';
      case CategoryType.transfer:
        return 'Transferência';
    }
  }
}
