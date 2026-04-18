import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/task_models.dart';
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
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
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
                              _ContactButtons(member: assignedMember),
                          ],
                        ),
                      ),
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
  final dynamic member;
  const _ContactButtons({this.member});

  @override
  Widget build(BuildContext context) {
    if (member == null) return const SizedBox();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.notifications_active, size: 20),
      tooltip: 'Remind',
      onSelected: (v) async {
        Uri? uri;
        switch (v) {
          case 'call':
            uri = Uri(scheme: 'tel', path: member.phone);
            break;
          case 'email':
            uri = Uri(scheme: 'mailto', path: member.email);
            break;
          case 'whatsapp':
            uri = Uri.parse('https://wa.me/${member.phone.replaceAll(RegExp(r'[^0-9]'), '')}');
            break;
          case 'messenger':
            uri = Uri.parse('https://m.me/');
            break;
        }
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'call', child: ListTile(leading: Icon(Icons.call), title: Text('Call'))),
        const PopupMenuItem(value: 'email', child: ListTile(leading: Icon(Icons.email), title: Text('Email'))),
        const PopupMenuItem(value: 'whatsapp', child: ListTile(leading: Icon(Icons.message), title: Text('WhatsApp'))),
        const PopupMenuItem(value: 'messenger', child: ListTile(leading: Icon(Icons.chat), title: Text('Messenger'))),
      ],
    );
  }
}


