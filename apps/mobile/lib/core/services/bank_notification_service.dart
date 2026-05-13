import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado do parse de uma notificação bancária.
class ParsedBankTransaction {
  final String bankPackage;
  final String bankName;
  final double amount;
  final String description;
  final String type; // 'expense' | 'income' | 'investment'
  final DateTime timestamp;
  final String rawBody;

  const ParsedBankTransaction({
    required this.bankPackage,
    required this.bankName,
    required this.amount,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.rawBody,
  });
}

/// Serviço que ouve notificações bancárias via EventChannel e parseia o conteúdo.
class BankNotificationService {
  static const _channel = EventChannel('com.example.fyna/bank_notifications');
  static const _pendingChannel =
      MethodChannel('com.example.fyna/pending_notifications');
  static const _pendingKey = 'pending_bank_notifications';

  static const _bankNames = {
    'br.com.intermedium': 'Banco Inter',
    'com.bradesco': 'Bradesco',
    'br.com.bb.android': 'Banco do Brasil',
    'com.itau': 'Itaú',
    'com.santander.app': 'Santander',
    'br.com.nubank': 'Nubank',
    'com.c6bank.app': 'C6 Bank',
    'br.com.original.bank': 'Original',
    'com.picpay': 'PicPay',
    'br.com.mercadopago.wallet': 'Mercado Pago',
    'br.com.sicredi.app': 'Sicredi',
    'br.com.caixa.economiafederal': 'Caixa',
  };

  Stream<ParsedBankTransaction>? _stream;

  /// Retorna stream de transações parseadas em tempo real (app em foreground).
  Stream<ParsedBankTransaction> get transactionStream {
    _stream ??= _channel
        .receiveBroadcastStream()
        .map((event) => _parse(event as String))
        .where((t) => t != null)
        .cast<ParsedBankTransaction>();
    return _stream!;
  }

  /// Recupera notificações que chegaram com o app fechado/background.
  /// Lê a fila do SharedPreferences (gravada pelo native side) e retorna
  /// as transações parseadas. Após chamar [clearPending] a fila é zerada.
  Future<List<ParsedBankTransaction>> getPendingTransactions() async {
    try {
      // Tenta primeiro via MethodChannel (caminho nativo)
      String? raw;
      try {
        raw = await _pendingChannel.invokeMethod<String>('getPending');
      } on MissingPluginException {
        // iOS ou canal não disponível — tenta via shared_preferences direto
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(_pendingKey);
      } on PlatformException {
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(_pendingKey);
      }
      if (raw == null || raw.isEmpty || raw == '[]') return [];

      final list = jsonDecode(raw) as List;
      return list
          .map((item) => _parse(jsonEncode(item)))
          .where((t) => t != null)
          .cast<ParsedBankTransaction>()
          .toList();
    } catch (e) {
      debugPrint('[BankNotification] Erro ao ler fila: $e');
      return [];
    }
  }

  /// Limpa a fila de notificações pendentes (chamar após processar todas).
  Future<void> clearPending() async {
    try {
      await _pendingChannel.invokeMethod('clearPending');
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingKey);
    } on PlatformException {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingKey);
    }
  }

  ParsedBankTransaction? _parse(String rawJson) {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final pkg = data['package'] as String;
      final title = data['title'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        (data['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      );

      final fullText = '$title $body'.toLowerCase();
      final amount = _extractAmount(fullText);
      if (amount == null) return null;

      final type = _detectType(fullText);
      final description = _buildDescription(title, body, type);

      return ParsedBankTransaction(
        bankPackage: pkg,
        bankName: _bankNames[pkg] ?? 'Banco',
        amount: amount,
        description: description,
        type: type,
        timestamp: timestamp,
        rawBody: body,
      );
    } catch (e) {
      debugPrint('[BankNotification] Erro ao parsear: $e');
      return null;
    }
  }

  /// Extrai valor monetário do texto da notificação.
  /// Suporta formatos: R$ 1.234,56 | R$1234.56 | 1.234,56
  double? _extractAmount(String text) {
    // Padrão BR: R$ 1.234,56
    final brPattern = RegExp(
      r'r\$\s*([\d]{1,3}(?:\.[\d]{3})*(?:,[\d]{2})?)',
      caseSensitive: false,
    );
    // Padrão decimal: 1234.56 ou 1,234.56
    final decPattern = RegExp(r'([\d]{1,3}(?:[.,][\d]{3})*[.,][\d]{2})');

    var match = brPattern.firstMatch(text);
    if (match != null) {
      return _parseAmount(match.group(1)!);
    }
    match = decPattern.firstMatch(text);
    if (match != null) {
      return _parseAmount(match.group(1)!);
    }
    return null;
  }

  double _parseAmount(String raw) {
    // Remove pontos de milhar e converte vírgula decimal
    final clean = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }

  /// Detecta se é despesa, receita ou investimento.
  String _detectType(String text) {
    const incomeKeywords = [
      'recebeu', 'recebido', 'crédito', 'creditado', 'pix recebido',
      'salário', 'transferência recebida', 'depósito', 'estorno',
    ];
    const investmentKeywords = [
      'investimento', 'aplicação', 'cdb', 'tesouro', 'fundo',
      'rendimento', 'resgate', 'ação', 'dividend',
    ];
    const expenseKeywords = [
      'compra', 'débito', 'debitado', 'pix enviado', 'pagamento',
      'transferência enviada', 'saque', 'fatura', 'boleto',
    ];

    for (final kw in investmentKeywords) {
      if (text.contains(kw)) return 'investment';
    }
    for (final kw in incomeKeywords) {
      if (text.contains(kw)) return 'income';
    }
    for (final kw in expenseKeywords) {
      if (text.contains(kw)) return 'expense';
    }
    // Default: débito (maioria das notificações bancárias são gastos)
    return 'expense';
  }

  String _buildDescription(String title, String body, String type) {
    if (body.isNotEmpty) return body;
    if (title.isNotEmpty) return title;
    return type == 'income' ? 'Receita bancária' : 'Despesa bancária';
  }
}
