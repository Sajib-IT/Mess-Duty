import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../models/task_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class TaskCompletionView extends StatelessWidget {
  const TaskCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskCtrl = Get.find<TaskController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Completion Requests')),
      body: Obx(() {
        final requests = taskCtrl.completionRequests;
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.verified,
            title: 'No pending requests',
            subtitle: 'All tasks are up to date!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (ctx, i) => _CompletionCard(completion: requests[i], taskCtrl: taskCtrl),
        );
      }),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final TaskCompletionModel completion;
  final TaskController taskCtrl;

  const _CompletionCard({required this.completion, required this.taskCtrl});

  @override
  Widget build(BuildContext context) {
    final task = taskCtrl.tasks.firstWhereOrNull((t) => t.taskId == completion.taskId);
    final member = taskCtrl.members.firstWhereOrNull((m) => m.uid == completion.requestedBy);
    final accepted = completion.acceptedBy.length;
    final required = completion.requiredAcceptances;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(task.taskType.icon, style: const TextStyle(fontSize: 20)),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task?.taskType.label ?? 'Task',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (member != null)
                        Row(
                          children: [
                            AppAvatar(photoUrl: member.photoUrl, name: member.name, radius: 10),
                            const SizedBox(width: 6),
                            Text(member.name,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress
            Row(
              children: [
                const Icon(Icons.verified_user, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text('$accepted of $required verifications needed'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: accepted / required,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => taskCtrl.rejectCompletion(completion),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => taskCtrl.acceptCompletion(completion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Verify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


