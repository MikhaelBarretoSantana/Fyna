import 'package:flutter/material.dart';
import 'package:fyna/core/constants/app_colors.dart';
import 'package:fyna/core/enums/notification_type.dart';
import 'package:fyna/feature/notifications/domain/entities/notification_entity.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // TODO: Substituir por dados da API
  final List<NotificationEntity> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Marcar todas',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkAccent : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.darkAccent : AppColors.primary,
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState(isDark)
              : _buildNotificationsList(isDark),
    );
  }

  Widget _buildNotificationsList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification, isDark);
      },
    );
  }

  Widget _buildNotificationItem(
      NotificationEntity notification, bool isDark) {
    final iconData = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.error,
        ),
      ),
      onDismissed: (_) {
        // TODO: Chamar API para deletar
        setState(() {
          _notifications.remove(notification);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDark ? const Color(0xFF14142A) : Colors.white)
              : (isDark
                  ? const Color(0xFF14142A)
                      .withValues(alpha: 0.8)
                  : AppColors.primary.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? (isDark
                    ? const Color(0xFF252540)
                    : const Color(0xFFEEEEF2))
                : (isDark
                    ? AppColors.darkAccent.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkAccent
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black45,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 56,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'Sem notificações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Você está em dia!',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.BUDGET_ALERT:
        return Icons.pie_chart_rounded;
      case NotificationType.GOAL_REACHED:
        return Icons.flag_rounded;
      case NotificationType.RECURRING_REMINDER:
        return Icons.repeat_rounded;
      case NotificationType.AI_INSIGHT:
        return Icons.smart_toy_rounded;
      case NotificationType.SYSTEM:
        return Icons.info_rounded;
      case NotificationType.WEEKLY_SUMMARY:
        return Icons.bar_chart_rounded;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.BUDGET_ALERT:
        return AppColors.warning;
      case NotificationType.GOAL_REACHED:
        return AppColors.success;
      case NotificationType.RECURRING_REMINDER:
        return AppColors.info;
      case NotificationType.AI_INSIGHT:
        return AppColors.accent;
      case NotificationType.SYSTEM:
        return AppColors.textSecondary;
      case NotificationType.WEEKLY_SUMMARY:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays}d';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _markAllAsRead() {
    // TODO: Chamar API
    setState(() {
      _unreadCount = 0;
    });
  }
}
