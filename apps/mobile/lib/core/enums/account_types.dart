/// Tipos de conta — espelha `AccountTypes` do backend.
enum AccountTypes {
  checking,
  savings,
  creditCard,
  cash,
  investment,
  digitalWallet,
  other;

  /// Converte string JSON (UPPER_SNAKE_CASE) para enum.
  static AccountTypes fromJson(String value) {
    switch (value) {
      case 'CHECKING':
        return AccountTypes.checking;
      case 'SAVINGS':
        return AccountTypes.savings;
      case 'CREDIT_CARD':
        return AccountTypes.creditCard;
      case 'CASH':
        return AccountTypes.cash;
      case 'INVESTMENT':
        return AccountTypes.investment;
      case 'DIGITAL_WALLET':
      case 'DIGITAL_wALLET': // typo no backend
        return AccountTypes.digitalWallet;
      case 'OTHER':
        return AccountTypes.other;
      default:
        return AccountTypes.other;
    }
  }

  /// Converte para string JSON (UPPER_SNAKE_CASE).
  String toJson() {
    switch (this) {
      case AccountTypes.checking:
        return 'CHECKING';
      case AccountTypes.savings:
        return 'SAVINGS';
      case AccountTypes.creditCard:
        return 'CREDIT_CARD';
      case AccountTypes.cash:
        return 'CASH';
      case AccountTypes.investment:
        return 'INVESTMENT';
      case AccountTypes.digitalWallet:
        return 'DIGITAL_WALLET';
      case AccountTypes.other:
        return 'OTHER';
    }
  }

  /// Label para exibição.
  String get label {
    switch (this) {
      case AccountTypes.checking:
        return 'Conta Corrente';
      case AccountTypes.savings:
        return 'Poupança';
      case AccountTypes.creditCard:
        return 'Cartão de Crédito';
      case AccountTypes.cash:
        return 'Dinheiro';
      case AccountTypes.investment:
        return 'Investimento';
      case AccountTypes.digitalWallet:
        return 'Carteira Digital';
      case AccountTypes.other:
        return 'Outro';
    }
  }
}
