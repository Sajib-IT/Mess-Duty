import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mess_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';
import '../../routes/app_routes.dart';

class MessSettingsView extends StatelessWidget {
  const MessSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MessController>();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Mess Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => Get.toNamed(Routes.SEARCH_INVITE),
            tooltip: 'Invite Members',
          ),
        ],
      ),
      body: Obx(() {
        final mess = ctrl.currentMess.value;
        final members = ctrl.members;
        if (mess == null) return const Center(child: CircularProgressIndicator());

        return ListView(
          children: [
            // Mess info card
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home_work, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mess.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(mess.address,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (mess.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(mess.description, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Created ${AppHelpers.formatDate(mess.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Members section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('Members (${members.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Invite'),
                    onPressed: () => Get.toNamed(Routes.SEARCH_INVITE),
                  ),
                ],
              ),
            ),
            ...members.map((m) => ListTile(
                  leading: AppAvatar(photoUrl: m.photoUrl, name: m.name, radius: 22),
                  title: Text(m.name),
                  subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (m.uid == mess.createdBy)
                        const Chip(
                          label: Text('Creator', style: TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (m.isAway)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Away',
                              style: TextStyle(color: AppColors.warning, fontSize: 11)),
                        ),
                    ],
                  ),
                )),
          ],
        );
      }),
    );
  }
}

