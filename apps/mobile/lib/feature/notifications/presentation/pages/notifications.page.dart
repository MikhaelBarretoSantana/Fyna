import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyna/config/injection/injection.dart';
import 'package:fyna/core/enums/notification_type.dart';
import 'package:fyna/core/errors/exceptions.dart';
import 'package:fyna/core/themes/theme_colors.dart';
import 'package:fyna/core/widgets/app_list_item.dart';
import 'package:fyna/core/widgets/app_screen_header.dart';
import 'package:fyna/core/widgets/icon_badge.dart';
import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationEntity> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<NotificationEntity>? _socketSub;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _socketSub = Injection.instance.notificationSocketService.notifications
        .listen(_onIncomingNotification);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  void _onIncomingNotification(NotificationEntity n) {
    if (!mounted) return;
    setState(() {
      _notifications = [n, ..._notifications.where((e) => e.id != n.id)];
    });
  }

  Future<void> _loadNotifications() async {
    if (!_isLoading) setState(() => _isLoading = true);
    setState(() => _errorMessage = null);
    try {
      final notifications =
          await Injection.instance.notificationRepository.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on NetworkException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sem conexão com a internet';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar notificações';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationEntity notification) async {
    if (notification.isRead) return;
    final original = List<NotificationEntity>.from(_notifications);
    setState(() {
      _notifications = _notifications
          .map((n) => n.id == notification.id
              ? n.copyWith(isRead: true, readAt: DateTime.now())
              : n)
          .toList();
    });
    try {
      await Injection.instance.notificationRepository
          .markAsRead(notification.id);
    } catch (_) {
      if (mounted) {
        setState(() => _notifications = original);
        _showSnack('Falha ao marcar como lida');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    final original = List<NotificationEntity>.from(_notifications);
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
    });
    try {
      await Injection.instance.notificationRepository.markAllAsRead();
    } catch (_) {
      if (mounted) {
        setState(() => _notifications = original);
        _showSnack('Falha ao marcar todas como lidas');
      }
    }
  }

  Future<void> _deleteNotification(NotificationEntity n) async {
    final original = List<NotificationEntity>.from(_notifications);
    setState(() => _notifications.removeWhere((x) => x.id == n.id));
    try {
      await Injection.instance.notificationRepository.deleteNotification(n.id);
    } catch (_) {
      if (mounted) {
        setState(() => _notifications = original);
        _showSnack('Falha ao excluir notificação');
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final tc = ThemeColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: tc.neoNegative,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.neoBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              title: 'Notificações',
              subtitle: _isLoading
                  ? 'Carregando...'
                  : _unreadCount == 0
                      ? 'Tudo em dia'
                      : '$_unreadCount não ${_unreadCount == 1 ? 'lida' : 'lidas'}',
              actions: [
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      foregroundColor: tc.neoTeal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Marcar todas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotifications,
                color: tc.neoTeal,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: tc.neoTeal))
                    : _errorMessage != null
                        ? _buildError(tc)
                        : _notifications.isEmpty
                            ? _buildEmpty(tc)
                            : _buildList(tc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeColors tc) {
    final grouped = _groupNotifications(_notifications);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: grouped.length,
      itemBuilder: (_, sectionIndex) {
        final entry = grouped.entries.elementAt(sectionIndex);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  4, sectionIndex == 0 ? 4 : 18, 0, 10),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: tc.neoTextFaint,
                ),
              ),
            ),
            for (final n in entry.value) ...[
              _NotificationTile(
                notification: n,
                onTap: () => _markAsRead(n),
                onDelete: () => _deleteNotification(n),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmpty(ThemeColors tc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBadge(
                  icon: Icons.notifications_none_rounded,
                  tone: 'neutral',
                  size: 64,
                  iconSize: 28,
                  radius: 18,
                ),
                const SizedBox(height: 14),
                Text(
                  'Nenhuma notificação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tc.neoTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Você verá aqui alertas, insights da IA\ne lembretes importantes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: tc.neoTextFaint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeColors tc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconBadge(
                    icon: Icons.error_outline_rounded,
                    tone: 'danger',
                    size: 56,
                    iconSize: 26,
                    radius: 16,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage ?? 'Erro inesperado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: tc.neoTextMuted),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _loadNotifications,
                    style: TextButton.styleFrom(foregroundColor: tc.neoTeal),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Agrupa por "Hoje", "Esta semana", "Anteriores".
  Map<String, List<NotificationEntity>> _groupNotifications(
    List<NotificationEntity> list,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final today_ = <NotificationEntity>[];
    final week = <NotificationEntity>[];
    final older = <NotificationEntity>[];

    for (final n in list) {
      final d = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      if (d == today) {
        today_.add(n);
      } else if (d.isAfter(weekAgo)) {
        week.add(n);
      } else {
        older.add(n);
      }
    }

    final result = <String, List<NotificationEntity>>{};
    if (today_.isNotEmpty) result['Hoje'] = today_;
    if (week.isNotEmpty) result['Esta semana'] = week;
    if (older.isNotEmpty) result['Anteriores'] = older;
    return result;
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  ({IconData icon, String tone}) _styleFor(NotificationType type) {
    switch (type) {
      case NotificationType.AI_INSIGHT:
        return (icon: Icons.auto_awesome_rounded, tone: 'ai');
      case NotificationType.BUDGET_ALERT:
        return (icon: Icons.notifications_rounded, tone: 'warning');
      case NotificationType.GOAL_PROGRESS:
        return (icon: Icons.flag_rounded, tone: 'transport');
      case NotificationType.GOAL_COMPLETED:
        return (icon: Icons.emoji_events_rounded, tone: 'success');
      case NotificationType.BILL_REMINDER:
        return (icon: Icons.event_outlined, tone: 'info');
      case NotificationType.RECURRING_TRANSACTION:
        return (icon: Icons.repeat_rounded, tone: 'info');
      case NotificationType.SPENDING_ANOMALY:
        return (icon: Icons.warning_amber_rounded, tone: 'danger');
      case NotificationType.INVESTMENT_RECOMMENDATION:
        return (icon: Icons.trending_up_rounded, tone: 'success');
      case NotificationType.WEEKLY_SUMMARY:
        return (icon: Icons.bar_chart_rounded, tone: 'transfer');
      case NotificationType.SECURITY:
        return (icon: Icons.shield_outlined, tone: 'health');
      case NotificationType.SYSTEM:
        return (icon: Icons.info_outline_rounded, tone: 'neutral');
    }
  }

  String _shortTime(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dd = DateTime(d.year, d.month, d.day);
    if (dd == today) return DateFormat('HH:mm').format(d);
    final diff = today.difference(dd).inDays;
    if (diff < 7) {
      // "Seg" / "Dom" / "Sáb"
      const dayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      return dayShort[(d.weekday - 1).clamp(0, 6)];
    }
    return DateFormat('dd/MM').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final style = _styleFor(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey('notif-${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: tc.neoNegative.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded, color: tc.neoNegative),
      ),
      onDismissed: (_) => onDelete(),
      child: AppListItem(
        onTap: onTap,
        leading: IconBadge(icon: style.icon, tone: style.tone),
        title: notification.title,
        subtitle: notification.message,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _shortTime(notification.createdAt),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: tc.neoTextFaint,
              ),
            ),
            const SizedBox(height: 6),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tc.neoNegative,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
