import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/task_models.dart';
import '../../models/user_model.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../routes/app_routes.dart';

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskCtrl = Get.find<TaskController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Tasks'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () => Get.toNamed(Routes.TASK_DETAIL),
            tooltip: 'Configure Tasks',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context, taskCtrl),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: Obx(() {
        final tasks = taskCtrl.tasks;
        if (tasks.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.task_outlined,
            title: 'No tasks yet',
            subtitle: 'Tasks will be initialized when the mess is created.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) => _TaskCard(task: tasks[i], taskCtrl: taskCtrl, authCtrl: authCtrl),
        );
      }),
    );
  }
}

void _showCreateTaskDialog(BuildContext context, TaskController taskCtrl) {
  final labelCtrl = TextEditingController();
  final selectedIcon = '📌'.obs;

  const emojis = [
    '📌','🧹','🛁','🍳','🧺','🪣','💡','🔧','🪴','🧴',
    '🚗','📦','🛒','🍽️','🧊','🪟','🚪','🛏️','🪑','🧯',
  ];

  Get.dialog(
    AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_task, color: Color(0xFF7B1FA2)),
          SizedBox(width: 8),
          Text('Create New Task'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: labelCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Task Name *',
                hintText: 'e.g. Room Cleaning',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emojis.map((e) => GestureDetector(
                onTap: () => selectedIcon.value = e,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedIcon.value == e
                        ? const Color(0xFF7B1FA2).withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedIcon.value == e
                          ? const Color(0xFF7B1FA2)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 20))),
                ),
              )).toList(),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        Obx(() => ElevatedButton.icon(
          onPressed: () async {
            final label = labelCtrl.text.trim();
            if (label.isEmpty) {
              Get.snackbar('Required', 'Please enter a task name.',
                  snackPosition: SnackPosition.BOTTOM);
              return;
            }
            Get.back();
            await taskCtrl.createTask(label: label, icon: selectedIcon.value);
          },
          icon: Text(selectedIcon.value, style: const TextStyle(fontSize: 16)),
          label: const Text('Create'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
        )),
      ],
    ),
  );
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskController taskCtrl;
  final AuthController authCtrl;

  const _TaskCard({required this.task, required this.taskCtrl, required this.authCtrl});

  Color get _color {
    switch (task.taskType) {
      case TaskType.teaMaking: return AppColors.teaMaking;
      case TaskType.bathroomCleaning: return AppColors.bathroomCleaning;
      case TaskType.basinCleaning: return AppColors.basinCleaning;
      case TaskType.waterFilterRefill: return AppColors.waterFilter;
      case TaskType.garbageDisposal: return AppColors.garbageDisposal;
      case TaskType.custom: return AppColors.customTask;
    }
  }

  void _confirmDelete(TaskModel t) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Task'),
      content: Text('Delete "${t.displayLabel}"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Get.back(); taskCtrl.deleteTask(t.taskId, t.displayLabel); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final groups = taskCtrl.getGroupsForTask(task.taskId);
      final members = taskCtrl.members;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(task.displayIcon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(task.displayLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text('${groups.length} group${groups.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                onPressed: () => Get.toNamed(Routes.TASK_DETAIL, arguments: task),
                tooltip: 'Configure Groups',
              ),
              if (task.taskType == TaskType.custom)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  onPressed: () => _confirmDelete(task),
                  tooltip: 'Delete Task',
                ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            ...groups.map((group) {
              final rotation = taskCtrl.getCurrentRotationForGroup(group.groupId);
              final assignedMember = rotation != null
                  ? members.firstWhereOrNull((m) => m.uid == rotation.assignedUserId)
                  : null;
              final isMe = rotation?.assignedUserId == authCtrl.currentUser.value?.uid;

              // Compute next 2 members in rotation (skip away members)
              final available = group.memberIds
                  .where((id) => members.any((m) => m.uid == id && !m.isAway))
                  .toList();
              final nextMembers = <UserModel>[];
              if (available.isNotEmpty) {
                // currentRotationIndex already points to who's NEXT after current
                final startIdx = group.currentRotationIndex % available.length;
                for (int offset = 0; offset < 2 && offset < available.length - 1; offset++) {
                  final uid = available[(startIdx + offset) % available.length];
                  // skip the currently assigned person
                  if (uid == rotation?.assignedUserId) continue;
                  final m = members.firstWhereOrNull((m) => m.uid == uid);
                  if (m != null) nextMembers.add(m);
                  if (nextMembers.length == 2) break;
                }
                // fallback: if we didn't get 2, fill from rotation order
                if (nextMembers.length < 2) {
                  for (int offset = 0; offset < available.length && nextMembers.length < 2; offset++) {
                    final uid = available[(startIdx + offset) % available.length];
                    if (uid == rotation?.assignedUserId) continue;
                    final m = members.firstWhereOrNull((m) => m.uid == uid);
                    if (m != null && !nextMembers.any((n) => n.uid == m.uid)) nextMembers.add(m);
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: Row(
                        children: [
                          Text(
                            group.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _color,
                            ),
                          ),
                          const Spacer(),
                          // Group member avatars
                          SizedBox(
                            height: 24,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: group.memberIds.take(4).map((id) {
                                final m = members.firstWhereOrNull((m) => m.uid == id);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: AppAvatar(
                                    photoUrl: m?.photoUrl,
                                    name: m?.name ?? '?',
                                    radius: 12,
                                    backgroundColor: m?.isAway == true ? Colors.grey : _color,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rotation != null) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                        child: Row(
                          children: [
                            AppAvatar(
                              photoUrl: assignedMember?.photoUrl,
                              name: assignedMember?.name ?? '?',
                              radius: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? 'Your turn!' : '${assignedMember?.name ?? "Unknown"}\'s turn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isMe ? _color : null,
                                    ),
                                  ),
                                  Text(
                                    rotation.status.value.capitalizeFirst ?? '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe && rotation.status == RotationStatus.pending)
                              ElevatedButton(
                                onPressed: () => taskCtrl.submitCompletion(rotation),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _color,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Mark Done', style: TextStyle(fontSize: 12)),
                              )
                            else if (!isMe && rotation.status == RotationStatus.pending)
                              _ContactButtons(member: assignedMember, rotation: rotation, task: task),
                          ],
                        ),
                      ),
                      // ── Up Next ───────────────────────────────────────
                      if (nextMembers.isNotEmpty) ...[
                        Divider(height: 1, color: Colors.grey.shade100),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: Row(
                            children: [
                              Icon(Icons.skip_next, size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                'Up next: ',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              ),
                              ...nextMembers.asMap().entries.map((e) {
                                final idx = e.key;
                                final m = e.value;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (idx > 0)
                                      Text(' → ', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                    AppAvatar(
                                      photoUrl: m.photoUrl,
                                      name: m.name,
                                      radius: 10,
                                      backgroundColor: _color.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.name.split(' ').first,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                        child: Row(
                          children: [
                            Text('No active rotation',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => taskCtrl.generateRotationForGroup(group.groupId),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Start', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ContactButtons extends StatelessWidget {
  final UserModel? member;
  final DutyRotationModel? rotation;
  final TaskModel task;

  const _ContactButtons({this.member, this.rotation, required this.task});

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open app',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showReminderDialog(BuildContext context) {
    final taskLabel  = task.taskType.label;
    final taskIcon   = task.taskType.icon;
    final memberName = member?.name ?? 'the member';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$taskIcon Send Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A push notification will be sent to $memberName reminding them to complete "$taskLabel".',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The notification will be delivered immediately to $memberName\'s device.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final pushService = Get.find<PushNotificationService>();

              if (member != null) {
                await pushService.sendToUser(
                  userId: member!.uid,
                  title: '$taskIcon Duty Reminder',
                  body:
                      'Hey $memberName! It\'s your turn for "$taskLabel". Please complete your mess duty.',
                );
              }

              Get.snackbar(
                '✅ Reminder Sent',
                'Push notification sent to $memberName',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.success,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              );
            },
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (member == null) return const SizedBox();
    final phone = member!.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final email = member!.email;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.notifications_active_outlined,
          size: 22, color: AppColors.primary),
      tooltip: 'Remind / Contact',
      onSelected: (v) async {
        switch (v) {
          case 'reminder':
            _showReminderDialog(context);
            break;
          case 'call':
            if (phone.isNotEmpty) await _launch(Uri(scheme: 'tel', path: phone));
            break;
          case 'whatsapp':
            if (phone.isNotEmpty) {
              final cleaned = phone.startsWith('+') ? phone.substring(1) : phone;
              final taskLabel = task.taskType.label;
              final taskIcon  = task.taskType.icon;
              final name      = member?.name.split(' ').first ?? 'there';
              final msg = Uri.encodeComponent(
                'Hi $name 👋,\n\n'
                'This is a friendly reminder from MessDuty.\n\n'
                '$taskIcon *$taskLabel* is assigned to you and is currently pending completion.\n\n'
                'Please complete your duty at your earliest convenience so your mess mates are not affected.\n\n'
                'Thank you! 🙏',
              );
              await _launch(Uri.parse('https://wa.me/$cleaned?text=$msg'));
            }
            break;
          case 'email':
            final taskLabel = task.taskType.label;
            final taskIcon  = task.taskType.icon;
            final name      = member?.name.split(' ').first ?? 'there';
            final subject   = Uri.encodeComponent('[MessDuty] Reminder: $taskLabel Duty Pending');
            final body      = Uri.encodeComponent(
              'Hi $name,\n\n'
              'This is a friendly reminder that your mess duty "$taskIcon $taskLabel" '
              'is currently assigned to you and is pending completion.\n\n'
              'Please ensure you complete it at your earliest convenience so that your mess '
              'mates are not inconvenienced.\n\n'
              'If you have already completed it, please mark it as done in the MessDuty app '
              'so the team can verify.\n\n'
              'Thank you for your cooperation!\n\n'
              'Best regards,\n'
              'MessDuty App',
            );
            await _launch(Uri.parse('mailto:$email?subject=$subject&body=$body'));
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'reminder',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.send, color: AppColors.primary),
            title: const Text('Send Reminder'),
            subtitle: const Text('Push notification to duty member',
                style: TextStyle(fontSize: 11)),
          ),
        ),
        if (phone.isNotEmpty) ...[
          PopupMenuItem(
            value: 'call',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call, color: AppColors.success),
              title: const Text('Call'),
              subtitle: Text(phone, style: const TextStyle(fontSize: 11)),
            ),
          ),
          PopupMenuItem(
            value: 'whatsapp',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.message, color: Color(0xFF25D366)),
              title: const Text('WhatsApp'),
              subtitle: Text(phone, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
        PopupMenuItem(
          value: 'email',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email, color: AppColors.info),
            title: const Text('Email'),
            subtitle: Text(email, style: const TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }
}


