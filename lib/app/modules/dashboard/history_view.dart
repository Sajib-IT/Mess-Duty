import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../dashboard/dashboard_controller.dart';
import '../../data/models/task_assignment_model.dart';

class HistoryView extends GetView<DashboardController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duty History')),
      body: Obx(() {
        if (controller.historyAssignments.isEmpty) {
          return const Center(child: Text('No history found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.historyAssignments.length,
          itemBuilder: (context, index) {
            final assignment = controller.historyAssignments[index];
            final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(assignment.assignedAt);
            
            return Card(
              child: ListTile(
                leading: Icon(
                  assignment.status == AssignmentStatus.completed 
                    ? Icons.check_circle : Icons.history,
                  color: assignment.status == AssignmentStatus.completed 
                    ? Colors.green : Colors.grey,
                ),
                title: Text(controller.getTaskTitle(assignment.taskId)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned to: ${controller.getUserName(assignment.memberId)}'),
                    Text(dateStr, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                trailing: Text(
                  assignment.status.name.capitalizeFirst!,
                  style: TextStyle(
                    color: assignment.status == AssignmentStatus.completed 
                      ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
