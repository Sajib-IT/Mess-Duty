import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../auth/auth_controller.dart';
import '../../data/models/task_assignment_model.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MessDuty Dashboard'),
        actions: [
          Obx(() => Switch(
            value: authController.userModel.value?.isAvailable ?? true,
            onChanged: (_) => authController.toggleAvailability(),
            activeColor: Colors.green,
          )),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Streams will update automatically, but we can add logic if needed
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, authController),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              const Text('Today\'s Duties', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTodayDuties(),
              const SizedBox(height: 24),
              const Text('Pending Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPendingRequests(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/request'),
        label: const Text('Request Duty'),
        icon: const Icon(Icons.add_alert_rounded),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthController auth) {
    return Obx(() => Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                auth.userModel.value?.name[0].toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${auth.userModel.value?.name ?? "User"}!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    auth.userModel.value?.isAvailable ?? true 
                      ? 'You are currently available' 
                      : 'You are at home (Unavailable)',
                    style: TextStyle(
                      color: auth.userModel.value?.isAvailable ?? true ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _ActionCard(icon: Icons.people, label: 'Members', onTap: () => Get.toNamed('/members')),
        const SizedBox(width: 12),
        _ActionCard(icon: Icons.history, label: 'History', onTap: () => Get.toNamed('/history')),
        const SizedBox(width: 12),
        _ActionCard(icon: Icons.settings, label: 'Tasks', onTap: () => Get.toNamed('/tasks')),
      ],
    );
  }

  Widget _buildTodayDuties() {
    return Obx(() {
      if (controller.todayAssignments.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No duties assigned for today yet.'),
        ));
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.todayAssignments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final assignment = controller.todayAssignments[index];
          final isCompleted = assignment.status == AssignmentStatus.completed;
          
          return ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.pending_actions,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            title: Text(controller.getTaskTitle(assignment.taskId)),
            subtitle: Text('Assigned to: ${controller.getUserName(assignment.memberId)}'),
            trailing: !isCompleted && assignment.memberId == Get.find<AuthController>().userModel.value?.id
              ? ElevatedButton(
                  onPressed: () => controller.completeTask(assignment.id),
                  child: const Text('Complete'),
                )
              : isCompleted ? const Text('Done', style: TextStyle(color: Colors.green)) : null,
          );
        },
      );
    });
  }

  Widget _buildPendingRequests() {
    return Obx(() {
      if (controller.pendingRequests.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No pending requests.'),
        ));
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.pendingRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final request = controller.pendingRequests[index];
          return ListTile(
            tileColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.notification_important, color: Colors.red),
            title: Text('${controller.getTaskTitle(request.taskId)} Requested'),
            subtitle: Text('By: ${controller.getUserName(request.requestedBy)}'),
            trailing: const Text('Processing...', style: TextStyle(fontStyle: FontStyle.italic)),
          );
        },
      );
    });
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
