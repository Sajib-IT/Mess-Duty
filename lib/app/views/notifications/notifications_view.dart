import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';
import '../../models/other_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/shared_widgets.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: ctrl.markAllRead,
            child: const Text('Mark All Read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Obx(() {
        final notifs = ctrl.notifications;
        if (notifs.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.notifications_none,
            title: 'No notifications',
            subtitle: 'You\'re all caught up!',
          );
        }

        final today = notifs.where((n) =>
            DateTime.now().difference(n.createdAt).inHours < 24).toList();
        final earlier = notifs.where((n) =>
            DateTime.now().difference(n.createdAt).inHours >= 24).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (today.isNotEmpty) ...[
              _SectionHeader('Today'),
              ...today.map((n) => _NotificationTile(notif: n, ctrl: ctrl)),
            ],
            if (earlier.isNotEmpty) ...[
              _SectionHeader('Earlier'),
              ...earlier.map((n) => _NotificationTile(notif: n, ctrl: ctrl)),
            ],
          ],
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final NotificationController ctrl;

  const _NotificationTile({required this.notif, required this.ctrl});

  IconData get _icon {
    switch (notif.type) {
      case NotificationType.dutyReminder: return Icons.assignment_late;
      case NotificationType.manualReminder: return Icons.notification_add;
      case NotificationType.completionRequest: return Icons.pending_actions;
      case NotificationType.completionApproved: return Icons.verified;
      case NotificationType.invitation: return Icons.mail;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotificationType.dutyReminder: return AppColors.warning;
      case NotificationType.manualReminder: return AppColors.info;
      case NotificationType.completionRequest: return AppColors.primary;
      case NotificationType.completionApproved: return AppColors.success;
      case NotificationType.invitation: return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.success,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      onDismissed: (_) => ctrl.markRead(notif.notificationId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : _color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead ? Colors.grey.shade200 : _color.withValues(alpha: 0.25),
          ),
        ),
        child: ListTile(
          onTap: () => ctrl.markRead(notif.notificationId),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          title: Text(
            notif.title,
            style: TextStyle(
              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notif.body, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                AppHelpers.timeAgo(notif.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          trailing: !notif.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                )
              : null,
        ),
      ),
    );
  }
}


