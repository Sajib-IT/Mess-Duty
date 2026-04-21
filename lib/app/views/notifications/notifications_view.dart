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
        if (ctrl.isRefreshing.value) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ShimmerList(count: 6, tileBuilder: () => const ShimmerNotifTile()),
          );
        }
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
      case NotificationType.dutyReminder:       return Icons.assignment_late;
      case NotificationType.manualReminder:     return Icons.notification_add;
      case NotificationType.completionRequest:  return Icons.pending_actions;
      case NotificationType.completionApproved: return Icons.verified;
      case NotificationType.completionRejected: return Icons.cancel_outlined;
      case NotificationType.invitation:         return Icons.mail_outline;
      case NotificationType.invitationAccepted: return Icons.how_to_reg;
      case NotificationType.memberJoined:       return Icons.person_add_alt_1;
      case NotificationType.memberLeft:         return Icons.person_remove_alt_1;
      case NotificationType.dutySkipped:        return Icons.skip_next;
      case NotificationType.rotationStarted:    return Icons.rotate_right;
      case NotificationType.messUpdated:        return Icons.edit_note;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotificationType.dutyReminder:       return AppColors.warning;
      case NotificationType.manualReminder:     return AppColors.info;
      case NotificationType.completionRequest:  return AppColors.primary;
      case NotificationType.completionApproved: return AppColors.success;
      case NotificationType.completionRejected: return AppColors.error;
      case NotificationType.invitation:         return AppColors.accent;
      case NotificationType.invitationAccepted: return AppColors.success;
      case NotificationType.memberJoined:       return AppColors.primaryLight;
      case NotificationType.memberLeft:         return Colors.blueGrey;
      case NotificationType.dutySkipped:        return AppColors.warning;
      case NotificationType.rotationStarted:    return AppColors.primary;
      case NotificationType.messUpdated:        return AppColors.info;
    }
  }

  String get _typeLabel {
    switch (notif.type) {
      case NotificationType.dutyReminder:       return 'Duty Reminder';
      case NotificationType.manualReminder:     return 'Reminder';
      case NotificationType.completionRequest:  return 'Verification';
      case NotificationType.completionApproved: return 'Approved';
      case NotificationType.completionRejected: return 'Rejected';
      case NotificationType.invitation:         return 'Invitation';
      case NotificationType.invitationAccepted: return 'Joined';
      case NotificationType.memberJoined:       return 'New Member';
      case NotificationType.memberLeft:         return 'Member Left';
      case NotificationType.dutySkipped:        return 'Skipped';
      case NotificationType.rotationStarted:    return 'Rotation';
      case NotificationType.messUpdated:        return 'Mess Update';
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
          color: notif.isRead ? Colors.white : _color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? Colors.grey.shade200 : _color.withValues(alpha: 0.3),
          ),
          boxShadow: [
            if (!notif.isRead)
              BoxShadow(color: _color.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: InkWell(
          onTap: () => ctrl.markRead(notif.notificationId),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type chip + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _typeLabel,
                              style: TextStyle(fontSize: 10, color: _color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppHelpers.timeAgo(notif.createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Title
                      Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Body
                      Text(
                        notif.body,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

