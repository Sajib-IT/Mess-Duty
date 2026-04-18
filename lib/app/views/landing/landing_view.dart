import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mess_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final messCtrl = Get.find<MessController>();
    final authCtrl = Get.find<AuthController>();

    final features = [
      {
        'icon': Icons.rotate_right,
        'title': 'Smart Rotation',
        'desc': 'Auto-rotate duties fairly among members, skipping away members.',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Smart Reminders',
        'desc': 'Get notified when it\'s your turn. Set custom reminders.',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.verified_user,
        'title': 'Task Validation',
        'desc': 'Tasks validated by 2 members to ensure quality.',
        'color': AppColors.success,
      },
      {
        'icon': Icons.bar_chart,
        'title': 'History & Stats',
        'desc': 'Track duty history with graphs and performance stats.',
        'color': AppColors.info,
      },
      {
        'icon': Icons.group,
        'title': 'Team Management',
        'desc': 'Manage members, invite friends, handle sub-groups.',
        'color': AppColors.warning,
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'MessDuty',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          onPressed: () => authCtrl.signOut(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final name = authCtrl.currentUser.value?.name ?? 'there';
                      return Text(
                        'Hello, ${name.split(' ').first}! 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Text(
                      'You\'re not in any mess yet.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pending invitations
          Obx(() {
            final invites = messCtrl.pendingInvitations;
            if (invites.isEmpty) return const SizedBox();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline, color: AppColors.accentDark, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pending Invitations',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentDark,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ...invites.map((inv) => ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.accent,
                          child: Icon(Icons.restaurant, color: Colors.white, size: 18),
                        ),
                        title: Text(inv.messName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Invited by ${inv.invitedByName}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => messCtrl.declineInvitation(inv.invitationId),
                              child: const Text('Decline', style: TextStyle(color: Colors.red)),
                            ),
                            ElevatedButton(
                              onPressed: () => messCtrl.acceptInvitation(inv),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            );
          }),

          // Feature showcase
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'What MessDuty offers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...features.map((f) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (f['color'] as Color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(f['icon'] as IconData,
                                  color: f['color'] as Color, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    f['desc'] as String,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () => Get.toNamed(Routes.CREATE_MESS),
            icon: const Icon(Icons.add_home),
            label: const Text('Create a Mess', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

