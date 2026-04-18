import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/task_models.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
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
    }
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
              child: Text(task.taskType.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(task.taskType.label,
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
                              _ContactButtons(member: assignedMember, rotation: rotation),
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

class _ContactButtons extends StatelessWidget {
  final UserModel? member;
  final DutyRotationModel? rotation;
  const _ContactButtons({this.member, this.rotation});

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open app', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showReminderDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Set Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send a scheduled notification to ${member?.name ?? 'this member'} reminding them of their duty.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = DateTime(
                        picked.year, picked.month, picked.day,
                        selectedTime.hour, selectedTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: AppColors.primary),
                title: Text(selectedTime.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                      selectedDate = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        picked.hour, picked.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final notifService = Get.find<NotificationService>();
                await notifService.scheduleReminder(
                  id: (rotation.hashCode ^ DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF,
                  title: '⏰ Duty Reminder',
                  body: '${member?.name ?? 'You'} — it\'s your turn! Please complete your assigned task.',
                  scheduledDate: selectedDate,
                );
                Get.snackbar(
                  'Reminder Set',
                  'Notification scheduled for ${selectedTime.format(context)}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                );
              },
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (member == null) return const SizedBox();
    final phone = (member!.phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    final email = member!.email;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.notifications_active_outlined, size: 22, color: AppColors.primary),
      tooltip: 'Remind / Contact',
      onSelected: (v) async {
        switch (v) {
          case 'call':
            if (phone.isNotEmpty) await _launch(Uri(scheme: 'tel', path: phone));
            break;
          case 'email':
            await _launch(Uri(
              scheme: 'mailto',
              path: email,
              queryParameters: {'subject': 'MessDuty Reminder', 'body': 'Hey, it\'s your turn for a mess duty!'},
            ));
            break;
          case 'whatsapp':
            if (phone.isNotEmpty) {
              final cleaned = phone.startsWith('+') ? phone.substring(1) : phone;
              await _launch(Uri.parse('https://wa.me/$cleaned?text=Hey+it\'s+your+turn+for+a+mess+duty!'));
            }
            break;
          case 'reminder':
            _showReminderDialog(context);
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'reminder',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm, color: AppColors.primary),
            title: const Text('Set Reminder'),
            subtitle: const Text('Schedule a notification', style: TextStyle(fontSize: 11)),
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


