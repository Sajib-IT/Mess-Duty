import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/dashboard_controller.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';

class TasksView extends GetView<DashboardController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tasks Rotation')),
      body: Obx(() {
        if (controller.allTasks.isEmpty) {
          return const Center(child: Text('No tasks found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.allTasks.length,
          itemBuilder: (context, index) {
            final task = controller.allTasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${task.type.name.capitalizeFirst} • ${task.membersOrder.length} members'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rotation Order:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        if (task.membersOrder.isEmpty)
                          const Text('No members assigned to this rotation.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        ...task.membersOrder.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final uid = entry.value;
                          final user = controller.allUsers.firstWhereOrNull((u) => u.id == uid);
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(radius: 12, child: Text('${idx + 1}', style: const TextStyle(fontSize: 10))),
                            title: Text(user?.name ?? 'Unknown'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                              onPressed: () => _removeMemberFromTask(task, uid),
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        TextButton.icon(
                          onPressed: () => _showAddMemberDialog(context, task),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Member to Rotation'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _removeMemberFromTask(TaskModel task, String uid) {
    final newOrder = List<String>.from(task.membersOrder)..remove(uid);
    controller.updateTaskMembers(task, newOrder);
  }

  void _showAddMemberDialog(BuildContext context, TaskModel task) {
    Get.dialog(
      AlertDialog(
        title: Text('Add Member to ${task.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.allUsers.length,
            itemBuilder: (context, index) {
              final user = controller.allUsers[index];
              if (task.membersOrder.contains(user.id)) return const SizedBox.shrink();
              return ListTile(
                title: Text(user.name),
                onTap: () {
                  final newOrder = List<String>.from(task.membersOrder)..add(user.id);
                  controller.updateTaskMembers(task, newOrder);
                  Get.back();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
