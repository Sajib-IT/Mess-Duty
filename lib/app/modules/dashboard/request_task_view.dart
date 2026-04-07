import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/dashboard_controller.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_request_model.dart';
import '../auth/auth_controller.dart';

class RequestTaskView extends GetView<DashboardController> {
  const RequestTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Duty')),
      body: Obx(() {
        final eventTasks = controller.allTasks.where((t) => t.type == TaskType.event).toList();
        
        if (eventTasks.isEmpty) {
          return const Center(child: Text('No event-based tasks available.'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: eventTasks.length,
          itemBuilder: (context, index) {
            final task = eventTasks[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.add_alert_rounded, color: Color(0xFF6750A4)),
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: ElevatedButton(
                  onPressed: () => _handleRequest(task),
                  child: const Text('Request'),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _handleRequest(TaskModel task) async {
    final authController = Get.find<AuthController>();
    
    // Create a request
    TaskRequestModel request = TaskRequestModel(
      id: '',
      taskId: task.id,
      requestedBy: authController.userModel.value?.id ?? 'system',
      createdAt: DateTime.now(),
    );

    await controller.createCustomRequest(request, task);
    Get.back(); // Return to dashboard
    Get.snackbar('Request Sent', '${task.title} has been requested.');
  }
}
