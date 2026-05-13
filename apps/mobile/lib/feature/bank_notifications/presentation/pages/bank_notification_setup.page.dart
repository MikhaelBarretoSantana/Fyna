import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyna/core/themes/theme_colors.dart';

/// Tela que solicita a permissão de acesso a notificações no Android.
class BankNotificationSetupPage extends StatefulWidget {
  const BankNotificationSetupPage({super.key});

  @override
  State<BankNotificationSetupPage> createState() =>
      _BankNotificationSetupPageState();
}

class _BankNotificationSetupPageState
    extends State<BankNotificationSetupPage> {
  static const _platform =
      MethodChannel('com.example.fyna/notification_permission');

  bool _hasPermission = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!Platform.isAndroid) {
      setState(() => _checking = false);
      return;
    }
    try {
      final granted =
          await _platform.invokeMethod<bool>('hasNotificationAccess') ?? false;
      setState(() {
        _hasPermission = granted;
        _checking = false;
      });
    } on PlatformException {
      setState(() => _checking = false);
    }
  }

  Future<void> _openSettings() async {
    try {
      await _platform.invokeMethod('openNotificationAccessSettings');
      // Aguarda usuário voltar e re-checa
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermission();
    } on PlatformException catch (e) {
      debugPrint('Erro ao abrir configurações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notificações Bancárias',
            style: TextStyle(color: tc.textPrimary)),
        iconTheme: IconThemeData(color: tc.textPrimary),
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(tc),
                  const SizedBox(height: 32),
                  _buildInfoSection(tc),
                  const Spacer(),
                  if (!_hasPermission) _buildPermissionButton(tc),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeColors tc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _hasPermission
            ? tc.success.withValues(alpha: 0.1)
            : tc.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasPermission
              ? tc.success.withValues(alpha: 0.3)
              : tc.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasPermission
                ? Icons.check_circle_rounded
                : Icons.notifications_off_rounded,
            color: _hasPermission ? tc.success : tc.warning,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasPermission ? 'Permissão concedida' : 'Permissão necessária',
                  style: TextStyle(
                    color: _hasPermission ? tc.success : tc.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasPermission
                      ? 'O Fyna está monitorando suas notificações bancárias.'
                      : 'Conceda acesso para registrar transações automaticamente.',
                  style: TextStyle(color: tc.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeColors tc) {
    final banks = [
      ('Banco Inter', Icons.account_balance_rounded),
      ('Bradesco', Icons.account_balance_rounded),
      ('Banco do Brasil', Icons.account_balance_rounded),
      ('Itaú', Icons.account_balance_rounded),
      ('Nubank', Icons.account_balance_rounded),
      ('Santander', Icons.account_balance_rounded),
      ('C6 Bank', Icons.account_balance_rounded),
      ('Caixa', Icons.account_balance_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Como funciona',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(
          'O Fyna lê as notificações dos seus aplicativos bancários e registra despesas, receitas e investimentos automaticamente — sem precisar digitar nada.',
          style: TextStyle(color: tc.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        Text('Bancos suportados',
            style: TextStyle(
                color: tc.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: banks
              .map((b) => Chip(
                    avatar: Icon(b.$2, size: 16, color: tc.primary),
                    label: Text(b.$1,
                        style:
                            TextStyle(color: tc.textPrimary, fontSize: 12)),
                    backgroundColor: tc.surface,
                    side: BorderSide(color: tc.border),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tc.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tc.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.security_rounded, color: tc.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seus dados ficam apenas no seu dispositivo e no seu servidor. O Fyna não compartilha informações com terceiros.',
                  style: TextStyle(color: tc.textSecondary, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionButton(ThemeColors tc) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _openSettings,
        icon: const Icon(Icons.settings_rounded),
        label: const Text('Conceder acesso nas configurações'),
        style: ElevatedButton.styleFrom(
          backgroundColor: tc.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
